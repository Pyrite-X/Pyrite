import 'dart:convert';

import 'package:alfred/alfred.dart';
import 'package:nyxx/nyxx.dart' show EmbedBuilder, EmbedFooterBuilder;
import 'package:onyx/onyx.dart';

import '../../utilities/base_embeds.dart' as embeds;

void helpCmd(Interaction interaction) async {
  HttpRequest request = interaction.metadata["request"];

  EmbedBuilder embedBuilder = embeds.infoEmbed();
  embedBuilder.title = "Invite Pyrite!";
  embedBuilder.description =
      "Invite Pyrite from [here](https://discord.com/api/oauth2/authorize?client_id=1022370218489692222&permissions=1374926720198&scope=bot%20applications.commands)!";
  embedBuilder.footer = EmbedFooterBuilder(text: "Guild ID: ${interaction.guild_id.toString()}");

  InteractionResponse response = InteractionResponse(InteractionResponseType.message_response, {
    "embeds": [
      {...embedBuilder.build()}
    ]
  });

  await request.response.send(jsonEncode(response));
}
