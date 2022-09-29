import 'dart:convert';

import 'package:alfred/alfred.dart';
import 'package:nyxx/nyxx.dart' show EmbedBuilder, DiscordColor;
import 'package:onyx/onyx.dart';

void configCmd(Interaction interaction) async {
  var interactionData = interaction.data! as ApplicationCommandData;

  HttpRequest request = interaction.metadata["request"];

  ApplicationCommandOption subcommand = interactionData.options![0];
  String optionName = subcommand.name;

  if (optionName == "logchannel") {
    var channelParameter = subcommand.options![0];
    configLogChannel(BigInt.parse(channelParameter.value), request);
  } else if (optionName == "phish_list") {
    configPhishingList(subcommand.options!, request);
  }
}

void configLogChannel(BigInt channelID, HttpRequest request) async {
  /// TODO: Change actual settings

  var embedBuilder = EmbedBuilder();
  embedBuilder.title = "Success!";
  embedBuilder.description = "Your log channel is now set to **<#${channelID}>**!";
  embedBuilder.color = DiscordColor.fromHexString("69c273");
  embedBuilder.timestamp = DateTime.now();

  InteractionResponse response = InteractionResponse(InteractionResponseType.message_response, {
    "embeds": [
      {...embedBuilder.build()}
    ]
  });

  await request.response.send(jsonEncode(response));
}

void configPhishingList(List<ApplicationCommandOption> options, HttpRequest request) async {
  if (options.isEmpty) {
    InteractionResponse response = InteractionResponse(InteractionResponseType.message_response, {
      "content":
          "The </config phish_list:1024817802558849064> command requires at least one option to be configured!",
      "flags": 1 << 6
    });

    await request.response.send(jsonEncode(response));
    return;
  }

  /// TODO: Change actual settings
  /// TODO: Consider responding differently if the setting is already configured that way or form old -> new option
  String result = "";
  for (ApplicationCommandOption option in options) {
    if (option.name == "enable") {
      result += "• Phishing list matching has been **${option.value == true ? 'enabled' : 'disabled'}**.\n";
    } else if (option.name == "action") {
      /// TODO: Replace value with expanded text used for choices.
      result += "• The action taken on a match has been set to **${option.value}**.\n";
    } else if (option.name == "fuzzy_match") {
      result +=
          "• A match will be found if a name is ~**${option.value.round()}%** similar to a name in the list.\n";
    } else if (option.name == "exclude") {
      result +=
          "• Users with the role <@&${option.value}> will be ignored if they match a name in the list.\n";
    }
  }

  var embedBuilder = EmbedBuilder();
  embedBuilder.title = "Success!";
  embedBuilder.addField(name: "Your Changes", content: result);
  embedBuilder.color = DiscordColor.fromHexString("69c273");
  embedBuilder.timestamp = DateTime.now();

  InteractionResponse response = InteractionResponse(InteractionResponseType.message_response, {
    "embeds": [
      {...embedBuilder.build()}
    ]
  });

  await request.response.send(jsonEncode(response));
}
