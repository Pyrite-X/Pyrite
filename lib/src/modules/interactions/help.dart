import 'dart:convert';

import 'package:alfred/alfred.dart';
import 'package:nyxx/nyxx.dart' show EmbedBuilder, EmbedFooterBuilder;
import 'package:onyx/onyx.dart';

import '../../utilities/base_embeds.dart' as embeds;

void helpCmd(Interaction interaction) async {
  HttpRequest request = interaction.metadata["request"];

  EmbedBuilder embedBuilder = embeds.warningEmbed();
  embedBuilder.title = "Help! I'm confused!";
  embedBuilder.description = "Need some help figuring out how to use Pyrite?\n\n"
      "Try reading one of these guides:\n"
      "1. [Setting up Pyrite](https://github.com/Pyrite-X/Pyrite/blob/main/guides/setting-up.md)\n"
      "2. [Pyrite's main concepts](https://github.com/Pyrite-X/Pyrite/blob/main/guides/main-concepts.md)\n\n"
      "Still confused? Join the [Support server](https://discord.gg/xzeWEDu4mj) for even more help!";
  embedBuilder.footer = EmbedFooterBuilder(text: "Guild ID: ${interaction.guild_id.toString()}");

  InteractionResponse response = InteractionResponse(InteractionResponseType.message_response, {
    "embeds": [
      {...embedBuilder.build()}
    ]
  });

  await request.response.send(jsonEncode(response));
}
