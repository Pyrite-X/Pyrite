import 'dart:convert';

import 'package:alfred/alfred.dart';
import 'package:nyxx/nyxx.dart' show EmbedBuilder, EmbedFooterBuilder, EmbedFieldBuilder;
import 'package:onyx/onyx.dart';
import 'package:pyrite/src/discord_http.dart';

import '../../structures/action.dart';
import '../../structures/server.dart';
import '../../backend/storage.dart' as storage;
import '../../utilities/base_embeds.dart' as embeds;

import 'whitelist.dart' as whitelist;

final RegExp ID_REGEX = RegExp(r'(\d{17,})');
const String _unicodeBlank = "\u{2800}";

/// Interaction entrypoint
Future<void> configCmd(Interaction interaction) async {
  var interactionData = interaction.data! as ApplicationCommandData;

  HttpRequest request = interaction.metadata["request"];

  ApplicationCommandOption subcommand = interactionData.options![0];
  String optionName = subcommand.name;

  if (optionName == "logchannel") {
    await configLogChannel(interaction, subcommand.options!, request);
  } else if (optionName == "bot_list") {
    await configBotList(interaction, subcommand.options!, request);
  } else if (optionName == "join_event") {
    var selection = subcommand.options![0];
    await configJoinEvent(interaction, selection.value, request);
  } else if (optionName == "view") {
    await viewServerConfig(interaction, request, subcommand);
  } else if (optionName == "whitelist") {
    await whitelist.whitelistLogic(interaction);
  }
}

/// Handle logic for configuring a log channel
Future<void> configLogChannel(
    Interaction interaction, List<ApplicationCommandOption> options, HttpRequest request) async {
  BigInt guildID = interaction.guild_id!;
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
  late EmbedBuilder embedBuilder;
  for (ApplicationCommandOption option in options) {
    if (option.name == "channel") {
      embedBuilder = embeds.successEmbed();
      BigInt channelID = BigInt.parse(option.value);
      description = "Your log channel is now set to **<#${channelID}>**!";
      await storage.updateGuildConfig(serverID: guildID, logchannelID: channelID);
    } else if (option.name == "clear") {
      if (option.value) {
        embedBuilder = embeds.warningEmbed();
        description = "Your set log channel has now been cleared!";
        await storage.removeGuildField(serverID: guildID, fieldName: "logchannelID");
      } else {
        embedBuilder = embeds.errorEmbed();
        description = "Your set log channel was not modified.";
      }
    }
  }

  embedBuilder.description = description;
  embedBuilder.footer = EmbedFooterBuilder(text: "Guild ID: ${interaction.guild_id.toString()}");

  InteractionResponse response = InteractionResponse(InteractionResponseType.message_response, {
    "embeds": [
      {...embedBuilder.build()}
    ],
    "allowed_mentions": {"parse": []}
  });

  await request.response.send(jsonEncode(response));
}

/// Handle logic for configuring the bot list
Future<void> configBotList(
    Interaction interaction, List<ApplicationCommandOption> options, HttpRequest request) async {
  BigInt guildID = interaction.guild_id!;
  if (options.isEmpty) {
    InteractionResponse response = InteractionResponse(InteractionResponseType.message_response, {
      "content":
          "The </config bot_list:1024817802558849064> command requires at least one option to be configured!",
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
          .writeln("• Bot list matching has been **${option.value == true ? 'enabled' : 'disabled'}**.");

      phishingMatchEnabled = option.value as bool;
    } else if (option.name == "action") {
      Action actions = Action.fromString(option.value);
      List<String> actionStringList = ActionEnumString.getStringsFromAction(actions);

      StringBuffer sBuffer = StringBuffer();

      sBuffer.write(
          "• The ${actionStringList.length != 1 ? 'actions' : 'action'} taken on a match has been set to:");
      actionStringList.forEach((element) {
        sBuffer.write("\n$_unicodeBlank- $element");
      });

      choicesString.writeln(sBuffer.toString());

      phishingMatchAction = actions;
    } else if (option.name == "fuzzy_match") {
      choicesString.writeln(
          "• A match will be found if a name is ~**${option.value}%** similar to a name in the list.");

      fuzzyMatchPercent = option.value;
    }
  }

  bool storageResult = await storage.updateGuildConfig(
      serverID: guildID,
      phishingMatchEnabled: phishingMatchEnabled,
      phishingMatchAction: phishingMatchAction,
      fuzzyMatchPercent: fuzzyMatchPercent);

  EmbedBuilder embedBuilder;
  if (storageResult) {
    embedBuilder = embeds.successEmbed();
    embedBuilder.fields!
        .add(EmbedFieldBuilder(name: "Your Changes", value: choicesString.toString(), isInline: false));
  } else {
    embedBuilder = embeds.warningEmbed();
    embedBuilder.description = "Your settings have not been changed from their current state.";
  }
  embedBuilder.footer = EmbedFooterBuilder(text: "Guild ID: ${interaction.guild_id.toString()}");

  await request.response.send(jsonEncode(InteractionResponse(InteractionResponseType.message_response, {
    "embeds": [
      {...embedBuilder.build()}
    ]
  })));
}

/// Handle logic for configuring the join event toggle
Future<void> configJoinEvent(Interaction interaction, bool selection, HttpRequest request) async {
  bool updateResult =
      await storage.updateGuildConfig(serverID: interaction.guild_id!, onJoinEvent: selection);

  EmbedBuilder embedBuilder;
  if (updateResult) {
    embedBuilder = embeds.successEmbed();
    embedBuilder.description = "Join event scanning has been **${selection ? 'enabled' : 'disabled'}**.";
  } else {
    embedBuilder = embeds.errorEmbed();
    embedBuilder.description = "Your settings have not been changed from their current state.";
  }

  embedBuilder.footer = EmbedFooterBuilder(text: "Guild ID: ${interaction.guild_id.toString()}");

  InteractionResponse response = InteractionResponse(InteractionResponseType.message_response, {
    "embeds": [
      {...embedBuilder.build()}
    ]
  });

  await request.response.send(jsonEncode(response));
}

/// Handle logic for configuring roles that Pyrite will ignore
Future<void> configExcludedRoles(Interaction interaction, String input, HttpRequest request) async {
  BigInt guildID = interaction.guild_id!;

  var matches = ID_REGEX.allMatches(input);
  List<BigInt> resultList = [];
  EmbedBuilder embedBuilder;

  bool withinTen = matches.length <= 10;

  if (input == "none") {
    embedBuilder = embeds.warningEmbed();
    embedBuilder.description = "Your list of roles that Pyrite will ignore is now empty.";

    await storage.removeGuildField(serverID: guildID, fieldName: "excludedRoles");
  } else if (matches.isNotEmpty && withinTen) {
    embedBuilder = embeds.successEmbed();
    StringBuffer choicesString = StringBuffer();

    choicesString.writeln("Users with these role(s) will be ignored on scans & on join:");
    matches.forEach((element) {
      String match = element[0]!;
      resultList.add(BigInt.parse(match));
      choicesString.writeln("$_unicodeBlank- <@&$match>");
    });

    embedBuilder.fields!
        .add(EmbedFieldBuilder(name: "Your Changes", value: choicesString.toString(), isInline: false));

    await storage.updateGuildConfig(serverID: guildID, excludedRoles: resultList);
  } else {
    embedBuilder = embeds.errorEmbed();
    if (!withinTen) {
      embedBuilder.description = "You're adding too many excluded roles! "
          "Please lower your number of choices from ${matches.length} roles to 10 roles.";
    } else {
      embedBuilder.description =
          "Your list of roles Pyrite will ignore has not changed because no valid options were found (role ID(s) or `none`).";
    }
  }

  embedBuilder.footer = EmbedFooterBuilder(text: "Guild ID: ${interaction.guild_id.toString()}");

  InteractionResponse response = InteractionResponse(InteractionResponseType.message_response, {
    "embeds": [
      {...embedBuilder.build()}
    ],
    "allowed_mentions": {"parse": []}
  });

  await request.response.send(jsonEncode(response));
}

/// Handle logic for viewing a server's settings.
Future<void> viewServerConfig(
    Interaction interaction, HttpRequest request, ApplicationCommandOption command) async {
  ApplicationCommandOption selection = command.options![0];
  String choice = selection.value;

  late EmbedBuilder embedBuilder;

  switch (choice) {
    case "summary":
      Server? serverData = await storage.fetchGuildData(interaction.guild_id!, withRules: true);

      if (serverData == null) {
        embedBuilder = embeds.warningEmbed();
        embedBuilder.description = "There was an issue getting your server data.";
        break;
      }
      embedBuilder = embeds.infoEmbed();
      embedBuilder.title = "Your server's settings:";

      int regexRuleCount = await storage.getGuildRegexRuleCount(serverData.serverID);

      String logchannel = (serverData.logchannelID != null) ? "<#${serverData.logchannelID}>" : "None";
      embedBuilder.fields!.add(EmbedFieldBuilder(
          name: "__General__",
          value: "**Check users on join?:** ${serverData.onJoinEnabled}\n"
              "**Log channel:** $logchannel\n"
              "**Rule count:** ${serverData.rules.length}/${storage.DEFAULT_RULE_LIMIT}\n"
              "**Regex rule count:** $regexRuleCount/${storage.DEFAULT_REGEX_RULE_LIMIT}",
          isInline: true));

      List<String> actionStrList = serverData.phishingMatchAction != null
          ? ActionEnumString.getStringsFromAction(serverData.phishingMatchAction!)
          : [];
      StringBuffer actionStr = StringBuffer();
      actionStrList.forEach((element) => actionStr.writeln("• $element"));

      embedBuilder.fields!.add(EmbedFieldBuilder(
          name: "__Bot List__",
          value: "**Checking enabled?:** ${serverData.checkPhishingList}\n"
              "**Action(s):**\n${actionStr.toString()}"
              "**Match Threshold:** ${serverData.fuzzyMatchPercent}%",
          isInline: true));

      embedBuilder.fields!.add(EmbedFieldBuilder(
          name: "__Whitelist Limits__",
          value: "**Name List**: ${serverData.excludedNames.length}/${whitelist.BASE_NAME_LIMIT}\n"
              "**Role List**: ${serverData.excludedRoles.length}/${whitelist.BASE_ROLE_LIMIT}",
          isInline: true));

      break;

    case "names":
      JsonData whitelistData = await storage.fetchGuildWhitelist(interaction.guild_id!);
      List<String> nameList = whitelistData["names"];
      if (nameList.isEmpty) {
        embedBuilder = embeds.warningEmbed();
        embedBuilder.description = "You have no whitelisted names to view!";
        break;
      }

      // Since the limit is 50 for now, just split the list into two inline fields
      // In the future if the limit is raised, paginate this.
      embedBuilder = embeds.infoEmbed();
      embedBuilder.title = "Your whitelisted names:";
      if (nameList.length > 25) {
        int median = (nameList.length / 2).round();
        var subOne = nameList.sublist(0, median);
        var subTwo = nameList.sublist(median);

        embedBuilder.fields!.add(
            EmbedFieldBuilder(name: "$_unicodeBlank", value: "- " + subOne.join("\n- "), isInline: true));

        embedBuilder.fields!.add(
            EmbedFieldBuilder(name: "$_unicodeBlank", value: "- " + subTwo.join("\n- "), isInline: true));
      } else {
        embedBuilder.fields!.add(
            EmbedFieldBuilder(name: "$_unicodeBlank", value: "- " + nameList.join("\n- "), isInline: false));
      }

      embedBuilder.footer = EmbedFooterBuilder(
          text: "You have ${nameList.length}/${whitelist.BASE_NAME_LIMIT} names whitelisted.");

      break;

    case "roles":
      JsonData whitelistData = await storage.fetchGuildWhitelist(interaction.guild_id!);
      List<BigInt> roleList = whitelistData["roles"];
      if (roleList.isEmpty) {
        embedBuilder = embeds.warningEmbed();
        embedBuilder.description = "You have no whitelisted roles to view!";
        break;
      }

      embedBuilder = embeds.infoEmbed();
      embedBuilder.title = "Your whitelisted roles:";
      List<String> stringifiedList = [for (BigInt roleID in roleList) "<@&$roleID> ($roleID)"];
      embedBuilder.description = "- " + stringifiedList.join("\n- ");
      embedBuilder.footer = EmbedFooterBuilder(
          text: "You have ${roleList.length}/${whitelist.BASE_ROLE_LIMIT} roles whitelisted.");

      break;

    default:
      embedBuilder = embeds.errorEmbed();
      embedBuilder.description = "You somehow caused the bot to receive an interaction "
          "without a proper action in the `config view` command. Bravo? Please report this.";
  }

  await request.response.send(jsonEncode(InteractionResponse(InteractionResponseType.message_response, {
    "embeds": [
      {...embedBuilder.build()}
    ],
    "allowed_mentions": {"parse": []}
  })));
}
