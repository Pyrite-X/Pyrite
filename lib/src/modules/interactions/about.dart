import 'dart:convert';

import 'package:alfred/alfred.dart';
import 'package:nyxx/nyxx.dart' show EmbedBuilder;
import 'package:onyx/onyx.dart';

import '../../utilities/base_embeds.dart' as embeds;

const String _unicodeBlank = "\u{2800}";

void aboutCmd(Interaction interaction) async {
  HttpRequest request = interaction.metadata["request"];

  var embedBuilder = embeds.infoEmbed();
  embedBuilder.title = "Here's some information about Pyrite!";
  embedBuilder.thumbnailUrl =
      "https://cdn.discordapp.com/avatars/1022370218489692222/5966690e72baa4b1ceca1b76c49ef0ed.webp?size=2048";
  embedBuilder.addField(
      name: "What is Pyrite?",
      content: "Pyrite is a bot focused on removing phishing bots!"
          "\nIn simpler terms, Pyrite tries to remove user accounts who "
          "try to mimic or look like large bots.\n${_unicodeBlank}",
      inline: false);

  embedBuilder.addField(
      name: "Why make Pyrite?",
      content: "While doing my stuff for [Bloxlink](https://blox.link), I noticed that a lot "
          "of large servers typically have many fake user accounts appearing like "
          "popular verification bots attempting to phish users (aka steal their account)."
          "\nSo just while thinking about why this is, I thought, why not make a bot that removes these accounts! "
          "And so, Pyrite came to be.\n${_unicodeBlank}",
      inline: false);

  embedBuilder.addField(
      name: "What is Pyrite coded in?",
      content: "[Dart!](https://dart.dev) With some self-made frameworks of my own, "
          "specifically [Lirx](https://github.com/One-Nub/Lirx) and [Onyx](https://github.com/One-Nub/Onyx). "
          "I also use [Nyxx](https://github.com/nyxx-discord/nyxx) for some gateway functionality, "
          "as well as for object representations.\n${_unicodeBlank}",
      inline: false);

  embedBuilder.addField(
      name: "Is Pyrite open source?",
      content: "It is! Check it out here: https://github.com/Pyrite-X/Pyrite",
      inline: false);

  embedBuilder.addFooter((footer) {
    footer.text = "Created by: Nub (@livesound) | Guild ID: ${interaction.guild_id}";
  });

  InteractionResponse response = InteractionResponse(InteractionResponseType.message_response, {
    "embeds": [
      {...embedBuilder.build()}
    ]
  });

  await request.response.send(jsonEncode(response));
}
