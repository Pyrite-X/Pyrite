import 'dart:convert';
import 'dart:io';

import 'package:alfred/alfred.dart';
import 'package:http/http.dart' as http;
import 'package:nyxx/nyxx.dart' show EmbedBuilder, EmbedFooterBuilder, EmbedFieldBuilder;
import 'package:onyx/onyx.dart';

import '../../discord_http.dart';
import '../../utilities/base_embeds.dart' as embeds;

Future<void> statsCommand(Interaction interaction, int startTime) async {
  HttpRequest request = interaction.metadata["request"];

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

  embedBuilder.fields!.add(EmbedFieldBuilder(name: "Servers", value: guildCount.toString(), isInline: true));
  embedBuilder.fields!.add(EmbedFieldBuilder(name: "Uptime", value: "<t:$startTime:R>", isInline: true));

  String memUsage = (ProcessInfo.currentRss / 1024 / 1024).toStringAsFixed(2);
  embedBuilder.fields!
      .add(EmbedFieldBuilder(name: "Memory Usage (RSS)", value: "$memUsage MB", isInline: true));

  var response = InteractionResponse(InteractionResponseType.message_response, {
    "embeds": [
      {...embedBuilder.build()}
    ]
  });
  await request.response.send(jsonEncode(response));
}
