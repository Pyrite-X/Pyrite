import 'dart:convert';

import 'package:alfred/alfred.dart';
import 'package:nyxx/nyxx.dart' show EmbedBuilder, DiscordColor;
import 'package:onyx/onyx.dart';

import '../../structures/action.dart';
import '../../structures/rule.dart';

void rulesCmd(Interaction interaction) async {
  var interactionData = interaction.data! as ApplicationCommandData;

  ApplicationCommandOption subcommand = interactionData.options![0];
  String optionName = subcommand.name;

  if (optionName == "view") {
    viewRules(interaction);
  } else if (optionName == "add") {
    addRule(interaction);
  } else if (optionName == "delete") {
    deleteRule(interaction);
  }
}

void viewRules(Interaction interaction) async {
  HttpRequest request = interaction.metadata["request"];

  InteractionResponse response = InteractionResponse(
      InteractionResponseType.message_response, {"content": "Still a WIP!", "flags": 1 << 6});

  request.response.send(jsonEncode(response));
}

void addRule(Interaction interaction) async {
  HttpRequest request = interaction.metadata["request"];

  InteractionResponse response = InteractionResponse(
      InteractionResponseType.message_response, {"content": "Still a WIP!", "flags": 1 << 6});

  request.response.send(jsonEncode(response));
}

void deleteRule(Interaction interaction) async {
  HttpRequest request = interaction.metadata["request"];

  InteractionResponse response = InteractionResponse(
      InteractionResponseType.message_response, {"content": "Still a WIP!", "flags": 1 << 6});

  request.response.send(jsonEncode(response));
}
