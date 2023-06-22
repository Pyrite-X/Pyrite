import 'dart:convert';

import 'package:alfred/alfred.dart';
import 'package:nyxx/nyxx.dart' show EmbedBuilder;
import 'package:onyx/onyx.dart';
import 'package:pyrite/src/discord_http.dart';
import 'package:unorm_dart/unorm_dart.dart' as unorm;

import '../../backend/storage.dart' as storage;
import '../../utilities/base_embeds.dart' as embeds;

final RegExp ID_REGEX = RegExp(r'(\d{17,})');

/// Interaction entrypoint
void whitelistLogic(Interaction interaction) async {
  var interactionData = interaction.data! as ApplicationCommandData;

  HttpRequest request = interaction.metadata["request"];

  ApplicationCommandOption subcommandGroup = interactionData.options![0];
  ApplicationCommandOption subcommand = subcommandGroup.options![0];

  String name = subcommand.name;
  switch (name) {
    case "names":
      _names(interaction, request.response, subcommand);
      break;

    case "roles":
      _roles(interaction, request.response, subcommand);
      break;

    case "view":
      _view(interaction, request.response, subcommand);
      break;

    default:
      print("Matching whitelist subcommand case was not found");
  }
}

void _names(Interaction interaction, HttpResponse response, ApplicationCommandOption command) async {
  ApplicationCommandOption selection = command.options![0];

  String action = selection.value;

  bool addOrDelete = ["add", "delete"].contains(action);

  // User gave a selection but didn't give a list of names.
  if (command.options?.length == 1 && addOrDelete) {
    InteractionResponse botResponse = InteractionResponse(InteractionResponseType.message_response, {
      "content": "This command (</config whitelist names:1089072171072102481>), "
          "with the option to **add** or **remove** whitelisted names, needs a list of names!\n"
          "Make sure you provide a value with the `names` argument when running the command.",
      "flags": 1 << 6
    });

    await response.send(jsonEncode(botResponse));
    return;
  }

  InteractionResponse deferResponse =
      InteractionResponse(InteractionResponseType.defer_message_response, null);
  await response.send(jsonEncode(deferResponse));

  late ApplicationCommandOption nameInput;
  List<String> nameInputList = [];
  JsonData whitelistData = {};

  if (addOrDelete) {
    nameInput = command.options!.last;
    // Split on comma, trim & normalize input, shove into a list.
    nameInputList = [for (String name in (nameInput.value as String).split(",")) unorm.nfkc(name.trim())];
  } else {
    whitelistData = await storage.fetchGuildWhitelist(interaction.guild_id!);
  }

  DiscordHTTP discordHTTP = DiscordHTTP();
  late EmbedBuilder embedResponse;
  ActionRow actionRow = ActionRow();

  switch (action) {
    case "add":
      bool success = await storage.addToWhitelist(interaction.guild_id!, names: nameInputList);

      if (success) {
        embedResponse = embeds.successEmbed();
        embedResponse.title = "Success!";
        embedResponse.description = "You changes to the whitelist have been saved successfully!\n\n"
            "You added these values to the name whitelist:\n> ${nameInput.value}";
      } else {
        embedResponse = embeds.errorEmbed();
        embedResponse.title = "Error!";
        embedResponse.description =
            "There was an issue saving your changes to the whitelist. Try again later!\n\n"
            "Here is the input you provided:\n> ${nameInput.value}";
      }

      break;

    case "delete":
      bool success = await storage.removeFromWhitelist(interaction.guild_id!, names: nameInputList);

      if (success) {
        embedResponse = embeds.successEmbed();
        embedResponse.title = "Success!";
        embedResponse.description = "You changes to the whitelist have been saved successfully!\n\n"
            "You removed these values from the name whitelist:\n> ${nameInput.value}";
      } else {
        embedResponse = embeds.errorEmbed();
        embedResponse.title = "Error!";
        embedResponse.description =
            "There was an issue saving your changes to the whitelist. Try again later!\n\n"
            "Here is the input you provided:\n> ${nameInput.value}";
      }

      break;

    case "clear":
      List<String> nameList = whitelistData["names"];

      if (nameList.isEmpty) {
        embedResponse = embeds.warningEmbed();
        embedResponse.description = "You have no names whitelisted! So therefore, there is nothing to clear!";
        break;
      }

      embedResponse = embeds.warningEmbed();
      embedResponse.title = "Are you sure you want to do this?";
      embedResponse.description = ">>> *Please confirm that you DO in fact want to "
          "clear your entire name whitelist.\n\n**THIS CANNOT BE UNDONE!***";

      // TODO: Implement button handlers.
      actionRow = ActionRow();
      actionRow.addComponent(Button(
          style: ButtonStyle.danger,
          label: "No",
          custom_id: "whitelist:clear:names:no:${interaction.member!["id"]}"));
      actionRow.addComponent(Button(
          style: ButtonStyle.success,
          label: "Yes",
          custom_id: "whitelist:clear:names:yes:${interaction.member!["id"]}"));
      break;

    default:
      embedResponse = embeds.errorEmbed();
      embedResponse.description = "You somehow caused the bot to receive an interaction "
          "without a proper action in the `whitelist names` command. Bravo? Please report this.";
  }

  await discordHTTP.sendFollowupMessage(interactionToken: interaction.token, payload: {
    "embeds": [
      {...embedResponse.build()}
    ],
    "components": [
      {...actionRow.toJson()}
    ],
    "allowed_mentions": {"parse": []}
  });
}

void _roles(Interaction interaction, HttpResponse response, ApplicationCommandOption command) async {
  InteractionResponse botResponse =
      InteractionResponse(InteractionResponseType.message_response, {"content": "WIP.", "flags": 1 << 6});

  await response.send(jsonEncode(botResponse));
  return;
}

void _view(Interaction interaction, HttpResponse response, ApplicationCommandOption command) async {
  InteractionResponse botResponse =
      InteractionResponse(InteractionResponseType.message_response, {"content": "WIP.", "flags": 1 << 6});

  await response.send(jsonEncode(botResponse));
  return;
}
