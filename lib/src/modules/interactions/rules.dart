import 'dart:convert';

import 'package:alfred/alfred.dart';
import 'package:nyxx/nyxx.dart' show EmbedBuilder, EmbedFooterBuilder;
import 'package:onyx/onyx.dart';

import '../../discord_http.dart';
import '../../structures/action.dart';
import '../../structures/rule.dart';
import '../../backend/storage.dart' as storage;
import '../../utilities/base_embeds.dart' as embeds;

void rulesCmd(Interaction interaction) async {
  var interactionData = interaction.data! as ApplicationCommandData;

  ApplicationCommandOption subcommand = interactionData.options![0];
  String optionName = subcommand.name;

  if (optionName == "view") {
    viewRules(interaction);
  } else if (optionName == "add") {
    addRule(interaction, subcommand.options!);
  } else if (optionName == "delete") {
    deleteRule(interaction, subcommand.options![0].value.toString());
  }
}

void viewRules(Interaction interaction) async {
  HttpRequest request = interaction.metadata["request"];

  InteractionResponse response = InteractionResponse(InteractionResponseType.defer_message_response, {});
  await request.response.send(jsonEncode(response));

  List<Rule> result = await storage.fetchGuildRules(interaction.guild_id!);

  ///TODO: Add pagination capabilities.
  late EmbedBuilder embedBuilder;
  StringBuffer description = StringBuffer();

  if (result.isEmpty) {
    embedBuilder = embeds.warningEmbed();
    description.writeln("You have no custom rules configured!");
    description.writeln("Get started with </rules add:1022784407704191009>!");
  } else {
    embedBuilder = embeds.infoEmbed();
    embedBuilder.title = "Your guild's custom rules:";
    result.forEach((element) => description.writeln(element.toString()));
  }

  embedBuilder.footer = EmbedFooterBuilder(text: "Guild ID: ${interaction.guild_id.toString()}");
  embedBuilder.description = description.toString();

  DiscordHTTP discordHTTP = DiscordHTTP();
  await discordHTTP.sendFollowupMessage(interactionToken: interaction.token, payload: {
    "embeds": [
      {...embedBuilder.build()}
    ]
  });
}

void addRule(Interaction interaction, List<ApplicationCommandOption> options) async {
  /// TODO: Add premium checks to determine if more can be added or if at limit.
  /// Also consider the checking for if a rule ID exists or not already.
  HttpRequest request = interaction.metadata["request"];

  InteractionResponse response = InteractionResponse(InteractionResponseType.defer_message_response, {});
  await request.response.send(jsonEncode(response));

  late EmbedBuilder embedBuilder;

  RuleBuilder ruleBuilder = RuleBuilder();
  ruleBuilder.generateRuleID();

  StringBuffer descBuffer = StringBuffer();

  /// No alternative since user object will be null since these commands don't work in DMs.
  /// Goes from member object > nested user object > id of said user object.
  if (interaction.member != null) {
    if (interaction.member!["user"] != null) {
      String userID = interaction.member!["user"]["id"];
      ruleBuilder.setAuthorID(BigInt.parse(userID));
    }
  }

  options.forEach((element) {
    if (element.name == "pattern") {
      ruleBuilder.setPattern(element.value);
    } else if (element.name == "action") {
      Action action = Action.fromString(element.value);
      ruleBuilder.setAction(action);
    } else if (element.name == "regex") {
      ruleBuilder.setRegexFlag(element.value);
    }
  });

  Rule builtRule = ruleBuilder.build();
  descBuffer.writeln(builtRule.toString());
  DiscordHTTP discordHTTP = DiscordHTTP();

  JsonData ruleStatus = await storage.canAddRule(interaction.guild_id!, rule: builtRule);
  bool canAdd = ruleStatus["flag"];
  String flagReason = ruleStatus["reason"];
  if (!canAdd) {
    embedBuilder = embeds.errorEmbed();
    embedBuilder.description = "$flagReason Try deleting some rules first!";
    embedBuilder.footer = EmbedFooterBuilder(text: "Guild ID: ${interaction.guild_id.toString()}");
    await discordHTTP.sendFollowupMessage(interactionToken: interaction.token, payload: {
      "embeds": [
        {...embedBuilder.build()}
      ]
    });
    return;
  }

  bool success = await storage.insertGuildRule(serverID: interaction.guild_id!, rule: builtRule);
  if (!success) {
    embedBuilder = embeds.warningEmbed();
    embedBuilder.description = "Your rule could not be created. This is likely because your defined pattern"
        " matches the pattern of an already existing rule.";
  } else {
    embedBuilder = embeds.successEmbed();
    embedBuilder.title = "New rule created:";
    embedBuilder.description = descBuffer.toString();
  }

  embedBuilder.footer = EmbedFooterBuilder(text: "Guild ID: ${interaction.guild_id.toString()}");
  await discordHTTP.sendFollowupMessage(interactionToken: interaction.token, payload: {
    "embeds": [
      {...embedBuilder.build()}
    ]
  });
}

void deleteRule(Interaction interaction, String ruleID) async {
  HttpRequest request = interaction.metadata["request"];

  InteractionResponse response = InteractionResponse(InteractionResponseType.defer_message_response, {});
  await request.response.send(jsonEncode(response));

  late EmbedBuilder embedBuilder;

  var result = await storage.removeGuildRule(serverID: interaction.guild_id!, ruleID: ruleID);

  if (!result) {
    embedBuilder = embeds.errorEmbed();
    embedBuilder.description = "Rule **$ruleID** could not be found.";
  } else {
    embedBuilder = embeds.successEmbed();
    embedBuilder.description = "Rule **$ruleID** was deleted.";
  }
  embedBuilder.footer = EmbedFooterBuilder(text: "Guild ID: ${interaction.guild_id.toString()}");

  DiscordHTTP discordHTTP = DiscordHTTP();
  await discordHTTP.sendFollowupMessage(interactionToken: interaction.token, payload: {
    "embeds": [
      {...embedBuilder.build()}
    ]
  });
}
