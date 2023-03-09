import 'dart:convert';

import 'package:alfred/alfred.dart';
import 'package:nyxx/nyxx.dart' show EmbedBuilder, EmbedFooterBuilder;
import 'package:onyx/onyx.dart';

import '../../utilities/base_embeds.dart' as embeds;

void helpCmd(Interaction interaction) async {
  HttpRequest request = interaction.metadata["request"];

  EmbedBuilder embedBuilder = embeds.warningEmbed();
  embedBuilder.title = "Help! I'm confused!";
  embedBuilder.description =
      "As Pyrite is currently in it's very alpha stages, there are no help documents, or a support server quite yet! \n\n"
      "Please stay tuned as development advances, a support server will be made and linked here soon!";
  embedBuilder.footer = EmbedFooterBuilder(text: "Guild ID: ${interaction.guild_id.toString()}");

  InteractionResponse response = InteractionResponse(InteractionResponseType.message_response, {
    "embeds": [
      {...embedBuilder.build()}
    ]
  });

  await request.response.send(jsonEncode(response));
}
