import 'dart:convert';

import 'package:alfred/alfred.dart';
import 'package:nyxx/nyxx.dart' show EmbedBuilder;
import 'package:onyx/onyx.dart';

import '../../../discord_http.dart';
import '../../../backend/storage.dart' as storage;
import '../../../utilities/base_embeds.dart' as embeds;

void roleMenuHandler(Interaction interaction) async {
  HttpResponse httpResponse = interaction.metadata["request"]!.response;
  MessageComponentData interactionData = interaction.data! as MessageComponentData;

  String customID = interactionData.custom_id;
  BigInt guildID = interaction.guild_id!;
  BigInt authorID = BigInt.parse(interaction.member!["user"]["id"]);

  var split_id = customID.split(":");
  String clearType = split_id[2];
  String userAction = split_id[3];
  BigInt userID = BigInt.parse(split_id[4]);

  if (userID != authorID) {
    InteractionResponse response = InteractionResponse(InteractionResponseType.message_response,
        {"content": "You did not run this command.", "flags": 1 << 6});
    await httpResponse.send(jsonEncode(response));
    return;
  }

  if (interactionData.values == null || interactionData.values!.isEmpty) {
    InteractionResponse response = InteractionResponse(InteractionResponseType.message_response,
        {"content": "You need to select at least one role to $userAction.", "flags": 1 << 6});
    await httpResponse.send(jsonEncode(response));
    return;
  }

  JsonData roleMap;
  if (interactionData.resolved!.containsKey("roles")) {
    roleMap = interactionData.resolved!["roles"];
    // Remove all managed roles (bot roles, integrations, linked roles)
    roleMap.removeWhere((key, value) => value["managed"]);
    if (roleMap.isEmpty) {
      InteractionResponse response = InteractionResponse(InteractionResponseType.message_response, {
        "content": "No valid roles were found to be ${userAction}ed. "
            "Bot roles and managed roles cannot be added.",
        "flags": 1 << 6
      });
      await httpResponse.send(jsonEncode(response));
      return;
    }
  } else {
    InteractionResponse response = InteractionResponse(InteractionResponseType.message_response,
        {"content": "No valid roles were found to be ${userAction}ed.", "flags": 1 << 6});
    await httpResponse.send(jsonEncode(response));
    return;
  }

  InteractionResponse deferResponse = InteractionResponse(InteractionResponseType.defer_update_message, null);
  await httpResponse.send(jsonEncode(deferResponse));

  DiscordHTTP discordHTTP = DiscordHTTP();
  late EmbedBuilder eb;

  bool storeChanges = false;
  List<BigInt> roleList = [for (var roleID in roleMap.keys) BigInt.parse(roleID.toString())];
  String roleStringList = "<@&" + roleList.join(">, <@&") + ">";

  if (userAction == "add") {
    storeChanges = await storage.addToWhitelist(guildID, roles: roleList);
  } else if (userAction == "delete") {
    storeChanges = await storage.removeFromWhitelist(guildID, roles: roleList);
  }

  if (storeChanges) {
    eb = embeds.successEmbed();
    eb.title = "Success!";

    eb.description = "Your changes to the role whitelist have been successfully saved."
        "You ${userAction}ed these roles:\n\n"
        "> *$roleStringList*";
  } else {
    eb = embeds.errorEmbed();
    eb.title = "Error!";
    eb.description = "Could not save your changes. This could be because of a database issue, "
        "or you chose roles that are not part of the stored whitelist.\n\n"
        "You tried to ${userAction} these roles:\n\n"
        "> *$roleStringList*";
  }

  await discordHTTP.editFollowupMessage(
      interactionToken: interaction.token,
      messageID: BigInt.parse(interaction.message!["id"]),
      payload: {
        "embeds": [
          {...eb.build()}
        ],
        "components": [],
        "allowed_mentions": {"parse": []},
      });
}
