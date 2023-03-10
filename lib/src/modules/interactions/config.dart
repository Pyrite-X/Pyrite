import 'dart:convert';

import 'package:alfred/alfred.dart';
import 'package:nyxx/nyxx.dart' show EmbedBuilder, EmbedFooterBuilder;
import 'package:onyx/onyx.dart';
import 'package:pyrite/src/discord_http.dart';

import '../../structures/action.dart';
import '../../structures/server.dart';
import '../../backend/storage.dart' as storage;
import '../../utilities/base_embeds.dart' as embeds;

final RegExp ID_REGEX = RegExp(r'(\d{17,})');

/// Interaction entrypoint
void configCmd(Interaction interaction) async {
  var interactionData = interaction.data! as ApplicationCommandData;

  HttpRequest request = interaction.metadata["request"];

  ApplicationCommandOption subcommand = interactionData.options![0];
  String optionName = subcommand.name;

  if (optionName == "logchannel") {
    configLogChannel(interaction, subcommand.options!, request);
  } else if (optionName == "phish_list") {
    configPhishingList(interaction, subcommand.options!, request);
  } else if (optionName == "join_event") {
    var selection = subcommand.options![0];
    configJoinEvent(interaction, selection.value, request);
  } else if (optionName == "excluded_roles") {
    var inputOption = subcommand.options![0];
    configExcludedRoles(interaction, inputOption.value, request);
  } else if (optionName == "view") {
    viewServerConfig(interaction, request);
  }
}

/// Handle logic for configuring a log channel
void configLogChannel(
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
      storage.updateGuildConfig(serverID: guildID, logchannelID: channelID);
    } else if (option.name == "clear") {
      if (option.value) {
        embedBuilder = embeds.warningEmbed();
        description = "Your set log channel has now been cleared!";
        storage.removeGuildField(serverID: guildID, fieldName: "logchannelID");
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

  request.response.send(jsonEncode(response));
}

/// Handle logic for configuring the phishing list
void configPhishingList(
    Interaction interaction, List<ApplicationCommandOption> options, HttpRequest request) async {
  BigInt guildID = interaction.guild_id!;
  if (options.isEmpty) {
    InteractionResponse response = InteractionResponse(InteractionResponseType.message_response, {
      "content":
          "The </config phish_list:1024817802558849064> command requires at least one option to be configured!",
      "flags": 1 << 6
    });

    await request.response.send(jsonEncode(response));
    return;
  }

  InteractionResponse response = InteractionResponse(InteractionResponseType.defer_message_response, {});
  await request.response.send(jsonEncode(response));

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

  bool storageResult = await storage.updateGuildConfig(
      serverID: guildID,
      phishingMatchEnabled: phishingMatchEnabled,
      phishingMatchAction: phishingMatchAction,
      fuzzyMatchPercent: fuzzyMatchPercent);

  EmbedBuilder embedBuilder;
  if (storageResult) {
    embedBuilder = embeds.successEmbed();
    embedBuilder.addField(name: "Your Changes", content: choicesString.toString());
  } else {
    embedBuilder = embeds.warningEmbed();
    embedBuilder.description = "Your settings have not been changed from their current state.";
  }
  embedBuilder.footer = EmbedFooterBuilder(text: "Guild ID: ${interaction.guild_id.toString()}");

  DiscordHTTP discordHTTP = DiscordHTTP();
  await discordHTTP.sendFollowupMessage(interactionToken: interaction.token, payload: {
    "embeds": [
      {...embedBuilder.build()}
    ]
  });
}

/// Handle logic for configuring the join event toggle
void configJoinEvent(Interaction interaction, bool selection, HttpRequest request) async {
  InteractionResponse response = InteractionResponse(InteractionResponseType.defer_message_response, {});
  await request.response.send(jsonEncode(response));

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

  DiscordHTTP discordHTTP = DiscordHTTP();
  await discordHTTP.sendFollowupMessage(interactionToken: interaction.token, payload: {
    "embeds": [
      {...embedBuilder.build()}
    ]
  });
}

/// Handle logic for configuring roles that Pyrite will ignore
void configExcludedRoles(Interaction interaction, String input, HttpRequest request) async {
  BigInt guildID = interaction.guild_id!;

  var matches = ID_REGEX.allMatches(input);
  List<BigInt> resultList = [];
  EmbedBuilder embedBuilder;

  bool withinTen = matches.length <= 10;

  if (input == "none") {
    embedBuilder = embeds.warningEmbed();
    embedBuilder.description = "Your list of roles that Pyrite will ignore is now empty.";
    storage.removeGuildField(serverID: guildID, fieldName: "excludedRoles");
  } else if (matches.isNotEmpty && withinTen) {
    embedBuilder = embeds.successEmbed();
    StringBuffer choicesString = StringBuffer();

    choicesString.writeln("Users with these role(s) will be ignored on scans & on join:");
    matches.forEach((element) {
      String match = element[0]!;
      resultList.add(BigInt.parse(match));
      choicesString.writeln("　- <@&$match>");
    });

    embedBuilder.addField(name: "Your Changes", content: choicesString.toString());
    storage.updateGuildConfig(serverID: guildID, excludedRoles: resultList);
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

void viewServerConfig(Interaction interaction, HttpRequest request) async {
  // Defer because awaiting db responses makes the final reply timeout
  InteractionResponse response = InteractionResponse(InteractionResponseType.defer_message_response, {});
  await request.response.send(jsonEncode(response));

  EmbedBuilder embedBuilder;
  Server? serverData = await storage.fetchGuildData(interaction.guild_id!, withRules: true);

  if (serverData == null) {
    embedBuilder = embeds.warningEmbed();
    embedBuilder.description = "There was an issue getting your server data.";
  } else {
    embedBuilder = embeds.infoEmbed();

    int regexRuleCount = await storage.getGuildRegexRuleCount(serverData.serverID);

    String logchannel = (serverData.logchannelID != null) ? "<#${serverData.logchannelID}>" : "None";
    embedBuilder.addField(
        name: "__General__",
        content: "**Check users on join?:** ${serverData.onJoinEnabled}\n"
            "**Log channel:** $logchannel\n"
            "**Rule count:** ${serverData.rules.length}/${storage.DEFAULT_RULE_LIMIT}\n"
            "**Regex rule count:** $regexRuleCount/${storage.DEFAULT_REGEX_RULE_LIMIT}",
        inline: true);

    List<String> actionStrList = serverData.phishingMatchAction != null
        ? ActionEnumString.getStringsFromAction(serverData.phishingMatchAction!)
        : [];
    StringBuffer actionStr = StringBuffer();
    actionStrList.forEach((element) => actionStr.writeln("• $element"));

    embedBuilder.addField(
        name: "__Phishing List__",
        content: "**Checking enabled?:** ${serverData.checkPhishingList}\n"
            "**Action(s):**\n${actionStr.toString()}"
            "**Match Percentage:** ${serverData.fuzzyMatchPercent}%",
        inline: true);

    if (serverData.excludedRoles.isNotEmpty) {
      StringBuffer output = StringBuffer();
      serverData.excludedRoles.forEach((element) => output.writeln("<@&${element}>"));
      embedBuilder.addField(name: "__Excluded Roles__", content: output, inline: true);
    }
  }
  embedBuilder.title = "Your server's settings";
  embedBuilder.addFooter((footer) {
    footer.text = "Guild ID: ${interaction.guild_id}";
  });

  DiscordHTTP discordHTTP = DiscordHTTP();
  await discordHTTP.sendFollowupMessage(interactionToken: interaction.token, payload: {
    "embeds": [
      {...embedBuilder.build()}
    ],
    "allowed_mentions": {"parse": []}
  });
}
