import 'dart:convert';

import 'package:alfred/alfred.dart';
import 'package:nyxx/nyxx.dart' show EmbedBuilder, DiscordColor;
import 'package:onyx/onyx.dart';

import '../../structures/action.dart';
import '../../backend/database.dart' as db;

void configCmd(Interaction interaction) async {
  var interactionData = interaction.data! as ApplicationCommandData;

  HttpRequest request = interaction.metadata["request"];

  ApplicationCommandOption subcommand = interactionData.options![0];
  String optionName = subcommand.name;

  BigInt guildID = interaction.guild_id!;

  if (optionName == "logchannel") {
    var channelParameter = subcommand.options![0];
    configLogChannel(guildID, BigInt.parse(channelParameter.value), request);
  } else if (optionName == "phish_list") {
    configPhishingList(guildID, subcommand.options!, request);
  } else if (optionName == "join_event") {
    configJoinEvent(guildID, subcommand.options!, request);
  }
}

void configLogChannel(BigInt guildID, BigInt channelID, HttpRequest request) async {
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

  db.updateGuildConfig(serverID: guildID, logchannelID: channelID);

  request.response.send(jsonEncode(response));
}

void configPhishingList(BigInt guildID, List<ApplicationCommandOption> options, HttpRequest request) async {
  if (options.isEmpty) {
    InteractionResponse response = InteractionResponse(InteractionResponseType.message_response, {
      "content":
          "The </config phish_list:1024817802558849064> command requires at least one option to be configured!",
      "flags": 1 << 6
    });

    await request.response.send(jsonEncode(response));
    return;
  }

  StringBuffer choicesString = StringBuffer();

  /// Probably not the most efficient to run the update command for each option passed... Will leave for now
  /// but if there are efficiency issues might rework.

  bool? phishingMatchEnabled;
  Action? phishingMatchAction;
  int? fuzzyMatchPercent;
  for (ApplicationCommandOption option in options) {
    if (option.name == "enable") {
      choicesString
          .writeln("• Phishing list matching has been **${option.value == true ? 'enabled' : 'disabled'}**.");

      phishingMatchEnabled = option.value as bool;
    } else if (option.name == "action") {
      Action actions = Action.fromString(option.value);
      List<String> actionStringList = ActionEnumString.getStringsFromAction(actions);

      StringBuffer sBuffer = StringBuffer();

      sBuffer.write(
          "• The ${actionStringList.length != 1 ? 'actions' : 'action'} taken on a match has been set to:");
      actionStringList.forEach((element) {
        sBuffer.write("\n　- $element");
      });

      choicesString.writeln(sBuffer.toString());

      phishingMatchAction = actions;
    } else if (option.name == "fuzzy_match") {
      choicesString.writeln(
          "• A match will be found if a name is ~**${option.value}%** similar to a name in the list.");

      fuzzyMatchPercent = option.value;
    }
  }

  db.updateGuildConfig(
      serverID: guildID,
      phishingMatchEnabled: phishingMatchEnabled,
      phishingMatchAction: phishingMatchAction,
      fuzzyMatchPercent: fuzzyMatchPercent);

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

void configJoinEvent(BigInt guildID, List<ApplicationCommandOption> options, HttpRequest request) async {
  if (options.isEmpty) {
    InteractionResponse response = InteractionResponse(InteractionResponseType.message_response, {
      "content":
          "The </config join_event:1025642564474388501> command requires at least one option to be configured!",
      "flags": 1 << 6
    });

    await request.response.send(jsonEncode(response));
    return;
  }

  StringBuffer choicesString = StringBuffer();

  for (ApplicationCommandOption option in options) {
    if (option.name == "enable") {
      choicesString
          .writeln("• Join event scanning has been **${option.value == true ? 'enabled' : 'disabled'}**.");

      db.updateGuildConfig(serverID: guildID, onJoinEvent: option.value);
    } else if (option.name == "action") {
      //TODO: Actions taken are on the lower level of rules and/or phishing list match.
      choicesString.writeln("• Stop trying to set the action on the join event. It has been removed.");
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
