import 'dart:convert';

import 'package:alfred/alfred.dart';
import 'package:nyxx/nyxx.dart' show EmbedBuilder;
import 'package:onyx/onyx.dart';

import '../../../discord_http.dart';
import '../../../backend/storage.dart' as storage;
import '../../../utilities/base_embeds.dart' as embeds;

Future<void> clearButtonHandler(Interaction interaction) async {
  HttpResponse httpResponse = interaction.metadata["request"]!.response;
  MessageComponentData interactionData = interaction.data! as MessageComponentData;

  String customID = interactionData.custom_id;
  BigInt guildID = interaction.guild_id!;
  BigInt authorID = BigInt.parse(interaction.member!["user"]["id"]);

  // ignore: non_constant_identifier_names
  var split_id = customID.split(":");
  String clearType = split_id[2];
  String userChoice = split_id[3];
  BigInt userID = BigInt.parse(split_id[4]);

  if (userID != authorID) {
    InteractionResponse response = InteractionResponse(InteractionResponseType.message_response,
        {"content": "You did not run this command.", "flags": 1 << 6});
    await httpResponse.send(jsonEncode(response));
    return;
  }

  JsonData message = interaction.message!;
  ActionRow row = ActionRow.fromJson(message["components"][0]);
  List<Component> components = row.components;

  // Disable the buttons.
  if (components[0].type == ComponentType.button) {
    (components[0] as Button).disabled = true;
  }
  if (components[1].type == ComponentType.button) {
    (components[1] as Button).disabled = true;
  }

  if (userChoice == "no") {
    EmbedBuilder eb = embeds.errorEmbed();
    eb.title = "Cancelled.";
    eb.description = "Your list of whitelisted $clearType have not been changed.";

    InteractionResponse response = InteractionResponse(InteractionResponseType.update_message, {
      "embeds": [eb.build()],
      "components": [row.toJson()]
    });
    await httpResponse.send(jsonEncode(response));
    return;
  }

  if (userChoice == "yes") {
    InteractionResponse response = InteractionResponse(InteractionResponseType.defer_update_message, null);
    await httpResponse.send(jsonEncode(response));

    bool roleSelection = clearType == "roles";

    bool result = await storage.clearWhitelist(guildID, roles: roleSelection, names: !roleSelection);
    late EmbedBuilder eb;

    if (result) {
      eb = embeds.successEmbed();
      eb.title = "Success!";
      eb.description = "Your list of whitelisted $clearType has been emptied.";
    } else {
      eb = embeds.errorEmbed();
      eb.title = "Error!";
      eb.description = "An issue occurred when clearing your list of whitelisted $clearType.";
    }

    DiscordHTTP discordHTTP = DiscordHTTP();
    await discordHTTP.editFollowupMessage(
        interactionToken: interaction.token,
        messageID: BigInt.parse(interaction.message!["id"]),
        payload: {
          "embeds": [eb.build()],
          "components": [row.toJson()]
        });
  }
}
