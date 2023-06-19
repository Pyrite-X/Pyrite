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

  if (isMember) {
    JsonData subUserData = userData["user"];

    username = subUserData["username"];
    discrim = subUserData["discriminator"];
    globalName = subUserData["global_name"];
    avatarHash = subUserData["avatar"];
    nickname = userData["nick"];

    String guildJoin = userData["joined_at"];
    guildJoinDate = DateTime.parse(guildJoin);
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

  embedBuilder.description = descBuffer.toString();

  await discordHTTP.sendFollowupMessage(interactionToken: interaction.token, payload: {
    "embeds": [
      {...embedBuilder.build()}
    ]
  });
}

void kickUser(
    Interaction interaction, HttpRequest request, BigInt authorID, BigInt guildID, BigInt userID) async {}

void banUser(
    Interaction interaction, HttpRequest request, BigInt authorID, BigInt guildID, BigInt userID) async {}
