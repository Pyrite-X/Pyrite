import 'dart:convert';

import 'package:alfred/alfred.dart';
import 'package:nyxx/nyxx.dart' show EmbedBuilder, DiscordColor;
import 'package:onyx/onyx.dart';

import '../../structures/action.dart';
import '../../backend/storage.dart' as storage;

void configCmd(Interaction interaction) async {
  var interactionData = interaction.data! as ApplicationCommandData;

  HttpRequest request = interaction.metadata["request"];

  ApplicationCommandOption subcommand = interactionData.options![0];
  String optionName = subcommand.name;

  BigInt guildID = interaction.guild_id!;

  if (optionName == "logchannel") {
    configLogChannel(guildID, subcommand.options!, request);
  } else if (optionName == "phish_list") {
    configPhishingList(guildID, subcommand.options!, request);
  } else if (optionName == "join_event") {
    var selection = subcommand.options![0];
    configJoinEvent(guildID, selection.value, request);
  } else if (optionName == "excluded_roles") {
    var inputOption = subcommand.options![0];
    configExcludedRoles(guildID, inputOption.value, request);
  }
}

void configLogChannel(BigInt guildID, List<ApplicationCommandOption> options, HttpRequest request) async {
  if (options.isEmpty) {
    InteractionResponse response = InteractionResponse(InteractionResponseType.message_response, {
      "content":
          "The </config logchannel:1022784407704191007> command requires at least one option to be configured!",
      "flags": 1 << 6
    });

    await request.response.send(jsonEncode(response));
    return;
  } else if (options.length > 1) {
    InteractionResponse response = InteractionResponse(InteractionResponseType.message_response, {
      "content":
          "You can't set a new log channel and clear the saved log channel at the same time!\nTry only setting the new log channel instead.",
      "flags": 1 << 6
    });

    await request.response.send(jsonEncode(response));
    return;
  }

  String description = "";
  for (ApplicationCommandOption option in options) {
    if (option.name == "channel") {
      BigInt channelID = BigInt.parse(option.value);
      description = "• Your log channel is now set to **<#${channelID}>**!";
      storage.updateGuildConfig(serverID: guildID, logchannelID: channelID);
    } else if (option.name == "clear") {
      if (option.value) {
        description = "• Your set log channel has now been cleared!";
        storage.removeGuildField(serverID: guildID, fieldName: "logchannelID");
      } else {
        description = "• Your set log channel was not modified.";
      }
    }
  }

  var embedBuilder = EmbedBuilder();
  embedBuilder.title = "Success!";
  embedBuilder.description = description;
  embedBuilder.color = DiscordColor.fromHexString("69c273");
  embedBuilder.timestamp = DateTime.now();

  InteractionResponse response = InteractionResponse(InteractionResponseType.message_response, {
    "embeds": [
      {...embedBuilder.build()}
    ]
  });

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

  storage.updateGuildConfig(
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

void configJoinEvent(BigInt guildID, bool selection, HttpRequest request) async {
  StringBuffer choicesString = StringBuffer();

  choicesString.writeln("• Join event scanning has been **${selection ? 'enabled' : 'disabled'}**.");
  storage.updateGuildConfig(serverID: guildID, onJoinEvent: selection);

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

final RegExp ID_REGEX = RegExp(r'(\d{17,})');
void configExcludedRoles(BigInt guildID, String input, HttpRequest request) async {
  var matches = ID_REGEX.allMatches(input);
  List<BigInt> resultList = [];

  StringBuffer choicesString = StringBuffer();

  if (input == "none") {
    choicesString.writeln("Your excluded role list has been cleared.");
    storage.removeGuildField(serverID: guildID, fieldName: "excludedRoles");
  } else if (matches.isNotEmpty) {
    choicesString.writeln("Users with these roles will be ignored on scans & on join:");
    matches.forEach((element) {
      String match = element[0]!;
      resultList.add(BigInt.parse(match));
      choicesString.writeln("　- <@&$match>");
    });
    storage.updateGuildConfig(serverID: guildID, excludedRoles: resultList);
  } else {
    choicesString.writeln(
        "Your excluded role list has not been modified because no valid options were found (role ID(s) or `none`).");
  }

  var embedBuilder = EmbedBuilder();
  embedBuilder.title = "Success!";
  embedBuilder.addField(name: "Your Changes", content: choicesString.toString());
  embedBuilder.color = DiscordColor.fromHexString("69c273");
  embedBuilder.timestamp = DateTime.now();

  InteractionResponse response = InteractionResponse(InteractionResponseType.message_response, {
    "embeds": [
      {...embedBuilder.build()}
    ],
    "allowed_mentions": {"parse": []}
  });

  await request.response.send(jsonEncode(response));
}
