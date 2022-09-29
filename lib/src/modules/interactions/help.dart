import 'dart:convert';

import 'package:alfred/alfred.dart';
import 'package:nyxx/nyxx.dart' show EmbedBuilder, DiscordColor;
import 'package:onyx/onyx.dart';

void helpCmd(Interaction interaction) async {
  HttpRequest request = interaction.metadata["request"];

  var embedBuilder = EmbedBuilder();
  embedBuilder.title = "Help! I'm confused!";
  embedBuilder.description =
      "As Pyrite is currently in it's very alpha stages, we have no help documents, or a support server! \n"
      "Please stay tuned as development advances, or until a support server is made.";
  embedBuilder.timestamp = DateTime.now();
  embedBuilder.color = DiscordColor.fromHexString("4D346D");

  InteractionResponse response = InteractionResponse(InteractionResponseType.message_response, {
    "embeds": [
      {...embedBuilder.build()}
    ]
  });

  await request.response.send(jsonEncode(response));
}
