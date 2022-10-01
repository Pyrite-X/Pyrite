import 'dart:convert';

import 'package:alfred/alfred.dart';
import 'package:nyxx/nyxx.dart' show EmbedBuilder, DiscordColor;
import 'package:onyx/onyx.dart';

import '../../structures/action.dart';

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
  } else if (optionName == "join_event") {
    configJoinEvent(subcommand.options!, request);
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
  StringBuffer choicesString = StringBuffer();

  for (ApplicationCommandOption option in options) {
    if (option.name == "enable") {
      choicesString
          .writeln("• Phishing list matching has been **${option.value == true ? 'enabled' : 'disabled'}**.");
    } else if (option.name == "action") {
      Action actions = Action.fromString(option.value);
      List<String> actionStringList = ActionEnumString.getStringsFromAction(actions);

      StringBuffer sBuffer = StringBuffer();

      sBuffer.writeln(
          "• The ${actionStringList.length != 1 ? 'actions' : 'action'} taken on a match has been set to:");
      actionStringList.forEach((element) {
        sBuffer.writeln("　- $element");
      });

      choicesString.writeln(sBuffer.toString());
    } else if (option.name == "fuzzy_match") {
      choicesString.writeln(
          "• A match will be found if a name is ~**${option.value.round()}%** similar to a name in the list.");
    } else if (option.name == "exclude") {
      choicesString.writeln(
          "• Users with the role <@&${option.value}> will be ignored if they match a name in the list.");
    }
  }

  var embedBuilder = EmbedBuilder();
  embedBuilder.title = "Success!";
  embedBuilder.addField(name: "Your Changes", content: choicesString.toString());
  embedBuilder.color = DiscordColor.fromHexString("69c273");
  embedBuilder.timestamp = DateTime.now();

  InteractionResponse response = InteractionResponse(InteractionResponseType.message_response, {
    "embeds": [
      {...embedBuilder.build()}
    ]
  });

  await request.response.send(jsonEncode(response));
}

void configJoinEvent(List<ApplicationCommandOption> options, HttpRequest request) async {
  if (options.isEmpty) {
    InteractionResponse response = InteractionResponse(InteractionResponseType.message_response, {
      "content":
          "The </config join_event:1025642564474388501> command requires at least one option to be configured!",
      "flags": 1 << 6
    });

    await request.response.send(jsonEncode(response));
    return;
  }

  //TODO: Actually change settings
  StringBuffer choicesString = StringBuffer();

  for (ApplicationCommandOption option in options) {
    if (option.name == "enable") {
      choicesString
          .writeln("• Join event scanning has been **${option.value == true ? 'enabled' : 'disabled'}**.");
    } else if (option.name == "action") {
      Action actions = Action.fromString(option.value);
      List<String> actionStringList = ActionEnumString.getStringsFromAction(actions);

      StringBuffer sBuffer = StringBuffer();

      sBuffer.writeln(
          "• The ${actionStringList.length != 1 ? 'actions' : 'action'} taken on a match has been set to:");
      actionStringList.forEach((element) {
        sBuffer.writeln("　- $element");
      });

      choicesString.writeln(sBuffer.toString());
    }
  }

  var embedBuilder = EmbedBuilder();
  embedBuilder.title = "Success!";
  embedBuilder.addField(name: "Your Changes", content: choicesString.toString());
  embedBuilder.color = DiscordColor.fromHexString("69c273");
  embedBuilder.timestamp = DateTime.now();

  InteractionResponse response = InteractionResponse(InteractionResponseType.message_response, {
    "embeds": [
      {...embedBuilder.build()}
    ]
  });

  await request.response.send(jsonEncode(response));
}
