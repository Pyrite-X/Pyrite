import 'dart:convert';

import 'package:alfred/alfred.dart';
import 'package:nyxx/nyxx.dart' show EmbedBuilder, DiscordColor;
import 'package:onyx/onyx.dart';

import '../../structures/action.dart';
import '../../backend/database.dart' show ServerQueries, PhishListQueries;

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

  ServerQueries db = ServerQueries();
  db.updateConfiguration(serverID: guildID, logchannelID: channelID);

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
  PhishListQueries db = PhishListQueries();

  /// Probably not the most efficient to run the update command for each option passed... Will leave for now
  /// but if there are efficiency issues might rework.
  for (ApplicationCommandOption option in options) {
    if (option.name == "enable") {
      choicesString
          .writeln("• Phishing list matching has been **${option.value == true ? 'enabled' : 'disabled'}**.");

      db.updateConfiguration(serverID: guildID, enabled: option.value as bool);
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

      db.updateConfiguration(serverID: guildID, action: actions);
    } else if (option.name == "fuzzy_match") {
      choicesString.writeln(
          "• A match will be found if a name is ~**${option.value}%** similar to a name in the list.");

      db.updateConfiguration(serverID: guildID, fuzzyMatchPercent: option.value);
    } else if (option.name == "exclude") {
      choicesString.writeln(
          "• Users with the role <@&${option.value}> will be ignored if they match a name in the list.");

      db.updateConfiguration(serverID: guildID, excludedRoles: [BigInt.parse(option.value)]);
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
  ServerQueries db = ServerQueries();

  for (ApplicationCommandOption option in options) {
    if (option.name == "enable") {
      choicesString
          .writeln("• Join event scanning has been **${option.value == true ? 'enabled' : 'disabled'}**.");

      db.updateConfiguration(serverID: guildID, joinEventHandling: option.value);
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

      db.updateConfiguration(serverID: guildID, joinAction: actions);
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
