import 'dart:convert';
import 'dart:io';

import 'package:alfred/alfred.dart';
import 'package:http/http.dart' as http;
import 'package:nyxx/nyxx.dart' show EmbedBuilder, EmbedFooterBuilder;
import 'package:onyx/onyx.dart';

import '../../discord_http.dart';
import '../../utilities/base_embeds.dart' as embeds;

void statsCommand(Interaction interaction, int startTime) async {
  HttpRequest request = interaction.metadata["request"];

  InteractionResponse response = InteractionResponse(InteractionResponseType.defer_message_response, {});
  await request.response.send(jsonEncode(response));

  EmbedBuilder embedBuilder = embeds.infoEmbed();
  embedBuilder.title = "Bot Statistics";

  embedBuilder.footer = EmbedFooterBuilder(text: "Guild ID: ${interaction.guild_id.toString()}");

  DiscordHTTP discordHTTP = DiscordHTTP();

  http.Response botObject = await discordHTTP.getBotApplication();
  JsonData botData = json.decode(botObject.body);
  int guildCount = 0;
  if (botData.containsKey("approximate_guild_count")) {
    guildCount = botData["approximate_guild_count"];
  }

  embedBuilder.addField(name: "Servers", content: guildCount, inline: true);
  embedBuilder.addField(name: "Uptime", content: "<t:${startTime}:R>", inline: true);

  String memUsage = (ProcessInfo.currentRss / 1024 / 1024).toStringAsFixed(2);
  embedBuilder.addField(name: "Memory Usage (RSS)", content: "${memUsage} MB", inline: true);

  await DiscordHTTP()
    ..sendFollowupMessage(interactionToken: interaction.token, payload: {
      "embeds": [
        {...embedBuilder.build()}
      ]
    });
}
