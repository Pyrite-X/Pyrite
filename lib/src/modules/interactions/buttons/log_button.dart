import 'dart:convert';

import 'package:alfred/alfred.dart';
import 'package:http/http.dart' as http;
import 'package:nyxx/nyxx.dart' show EmbedBuilder, EmbedAuthorBuilder, Snowflake;
import 'package:onyx/onyx.dart';

import '../../../discord_http.dart';
import '../../../utilities/base_embeds.dart';

void logButtonHandler(Interaction interaction) async {
  HttpRequest request = interaction.metadata["request"];
  MessageComponentData interactionData = interaction.data! as MessageComponentData;

  String customID = interactionData.custom_id;
  BigInt guildID = interaction.guild_id!;
  BigInt authorID = BigInt.parse(interaction.member!["user"]["id"]);

  var split_id = customID.split(":");
  String buttonType = split_id[1];
  BigInt userID = BigInt.parse(split_id[2]);

  switch (buttonType) {
    case "info":
      showUserInfo(interaction, request, guildID, userID);
      return;
    case "kick":
      kickUser(interaction, request, authorID, guildID, userID);
      return;
    case "ban":
      banUser(interaction, request, authorID, guildID, userID);
      return;
  }
}

void showUserInfo(Interaction interaction, HttpRequest request, BigInt guildID, BigInt userID) async {
  InteractionResponse response = InteractionResponse(InteractionResponseType.defer_message_response, {});
  await request.response.send(jsonEncode(response));

  DiscordHTTP discordHTTP = DiscordHTTP();

  JsonData userData = {};
  http.Response memberObject = await discordHTTP.getGuildMember(guildID: guildID, userID: userID);
  bool isMember = (memberObject.statusCode == 200);

  if (!isMember) {
    http.Response userObject = await discordHTTP.getUser(userID: userID);
    if (userObject.statusCode != 200) {
      var embedBuilder = warningEmbed();
      embedBuilder.description = "User info could not be gotten at this time!";

      await discordHTTP.sendFollowupMessage(interactionToken: interaction.token, payload: {
        "embeds": [
          {...embedBuilder.build()}
        ]
      });
      return;
    }

    userData = jsonDecode(userObject.body);
  } else {
    userData = jsonDecode(memberObject.body);
  }

  EmbedBuilder embedBuilder = infoEmbed();
  StringBuffer descBuffer = StringBuffer();

  late String username;
  late String discrim;
  String? globalName;
  String? avatarHash;

  DateTime userCreation = Snowflake(userID).timestamp;
  int mseUserCreation = (userCreation.millisecondsSinceEpoch / 1000).round();

  String? nickname;
  DateTime? guildJoinDate;
  List<dynamic> roleList = [];

  if (isMember) {
    JsonData subUserData = userData["user"];

    username = subUserData["username"];
    discrim = subUserData["discriminator"];
    globalName = subUserData["global_name"];
    avatarHash = subUserData["avatar"];
    nickname = userData["nick"];

    String guildJoin = userData["joined_at"];
    guildJoinDate = DateTime.parse(guildJoin);

    roleList = userData["roles"];
  } else {
    username = userData["username"];
    discrim = userData["discriminator"];
    globalName = userData["global_name"];
    avatarHash = userData["avatar"];
  }

  String userTitle =
      discrim == "0" ? "@$username${globalName != null ? ' (aka $globalName)' : ''}" : "$username#$discrim";
  embedBuilder.author = EmbedAuthorBuilder(name: userTitle);
  if (avatarHash != null) {
    embedBuilder.thumbnailUrl = "https://cdn.discordapp.com/avatars/${userID}/${avatarHash}.webp";
  }

  descBuffer.writeln("> <@$userID>");
  if (nickname != null) {
    descBuffer.writeln("> *Nickname*: $nickname");
  }

  embedBuilder.addField(name: "Discord join date:", content: "<t:$mseUserCreation:D>", inline: true);

  if (guildJoinDate != null) {
    int mseGuildJoin = (guildJoinDate.millisecondsSinceEpoch / 1000).round();
    embedBuilder.addField(name: "Server join date:", content: "<t:$mseGuildJoin:D>", inline: true);
  }

  if (roleList.isNotEmpty) {
    StringBuffer sb = StringBuffer();
    roleList.forEach((element) => sb.write("<@&$element> "));

    embedBuilder.addField(name: "Roles", content: sb.toString());
  }

  embedBuilder.description = descBuffer.toString();

  await discordHTTP.sendFollowupMessage(interactionToken: interaction.token, payload: {
    "embeds": [
      {...embedBuilder.build()}
    ]
  });
}

void kickUser(
  Interaction interaction,
  HttpRequest request,
  BigInt authorID,
  BigInt guildID,
  BigInt userID,
) async {
  InteractionResponse response = InteractionResponse(InteractionResponseType.message_response, null);

  DiscordHTTP discordHTTP = DiscordHTTP();

  // Check author permissions
  JsonData authorMemberData = interaction.member!;

  int? permissions = int.tryParse(authorMemberData["permissions"]);
  if (permissions != null) {
    if (permissions & (1 << 1) == 0) {
      response.data = {
        "content": "You don't have permissions to kick users in this server.",
        "flags": 1 << 6
      };
      await request.response.send(jsonEncode(response));
      return;
    }
  } else {
    response.data = {
      "content": "I could not check your permissions to make sure that you can kick people. Try again later!",
      "flags": 1 << 6
    };
    await request.response.send(jsonEncode(response));
    return;
  }

  // Check the bot's permissions
  if (interaction.app_permissions != null) {
    if (int.parse(interaction.app_permissions!) & (1 << 1) == 0) {
      response.data = {
        "content": "I can't kick people! Give me the permission to kick people and try again.",
        "flags": 1 << 6
      };
      await request.response.send(jsonEncode(response));
      return;
    }
  } else {
    response.data = {
      "content": "I could not check my permissions to make sure that I can kick people. Try again later!",
      "flags": 1 << 6
    };
    await request.response.send(jsonEncode(response));
    return;
  }

  String content = "User <@$userID> was kicked from your server.";
  String userMention = authorMemberData["user"]["discriminator"] != "0"
      ? "${authorMemberData["user"]["username"]}#${authorMemberData["user"]["discriminator"]}"
      : "@${authorMemberData["user"]["username"]}";

  response.responseType = InteractionResponseType.defer_message_response;
  await request.response.send(jsonEncode(response));

  await discordHTTP.kickUser(
    guildID: guildID,
    userID: userID,
    logReason: "User was manually kicked by \"$userMention\".",
  );

  response.data = {"content": content};
  await discordHTTP.sendFollowupMessage(interactionToken: interaction.token, payload: {"content": content});

  JsonData message = interaction.message!;
  List<dynamic> messageComponents = message["components"][0]["components"];
  // Disable the kick button.
  messageComponents[1]["disabled"] = true;

  await discordHTTP.editMessage(
      channelID: interaction.channel_id!,
      messageID: BigInt.parse(interaction.message!["id"]),
      payload: message);
}

void banUser(
  Interaction interaction,
  HttpRequest request,
  BigInt authorID,
  BigInt guildID,
  BigInt userID,
) async {
  InteractionResponse response = InteractionResponse(InteractionResponseType.message_response, null);

  DiscordHTTP discordHTTP = DiscordHTTP();

  // Check author permissions
  JsonData authorMemberData = interaction.member!;

  int? permissions = int.tryParse(authorMemberData["permissions"]);
  if (permissions != null) {
    if (permissions & (1 << 2) == 0) {
      response.data = {"content": "You don't have permissions to ban users in this server.", "flags": 1 << 6};
      await request.response.send(jsonEncode(response));
      return;
    }
  } else {
    response.data = {
      "content": "I could not check your permissions to make sure that you can ban people. Try again later!",
      "flags": 1 << 6
    };
    await request.response.send(jsonEncode(response));
    return;
  }

  // Check the bot's permissions
  if (interaction.app_permissions != null) {
    if (int.parse(interaction.app_permissions!) & (1 << 2) == 0) {
      response.data = {
        "content": "I can't ban people! Give me the permission to ban people and try again.",
        "flags": 1 << 6
      };
      await request.response.send(jsonEncode(response));
      return;
    }
  } else {
    response.data = {
      "content": "I could not check my permissions to make sure that I can ban people. Try again later!",
      "flags": 1 << 6
    };
    await request.response.send(jsonEncode(response));
    return;
  }

  String content = "User <@$userID> was banned from your server.";
  String userMention = authorMemberData["user"]["discriminator"] != "0"
      ? "${authorMemberData["user"]["username"]}#${authorMemberData["user"]["discriminator"]}"
      : "@${authorMemberData["user"]["username"]}";

  response.responseType = InteractionResponseType.defer_message_response;
  await request.response.send(jsonEncode(response));

  await discordHTTP.banUser(
    guildID: guildID,
    userID: userID,
    logReason: "User was manually banned by \"$userMention\".",
  );

  response.data = {"content": content};
  await discordHTTP.sendFollowupMessage(interactionToken: interaction.token, payload: {"content": content});

  JsonData message = interaction.message!;
  List<dynamic> messageComponents = message["components"][0]["components"];
  // Disable both kick and ban buttons.
  messageComponents[1]["disabled"] = true;
  messageComponents[2]["disabled"] = true;

  await discordHTTP.editMessage(
      channelID: interaction.channel_id!,
      messageID: BigInt.parse(interaction.message!["id"]),
      payload: message);
}
