import 'dart:convert';

import 'package:alfred/alfred.dart';
import 'package:nyxx/nyxx.dart' show EmbedBuilder, DiscordColor;
import 'package:onyx/onyx.dart';

import '../../discord_http.dart';
import '../../structures/action.dart';
import '../../structures/rule.dart';
import '../../backend/storage.dart' as storage;

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

  InteractionResponse response =
      InteractionResponse(InteractionResponseType.defer_message_response, {"flags": 1 << 6});
  await request.response.send(jsonEncode(response));

  List<dynamic> result = await storage.fetchGuildRules(interaction.guild_id!);

  ///TODO: Add pagination capabilities.
  EmbedBuilder embedBuilder = EmbedBuilder();
  embedBuilder.title = "Server Custom Rule List";
  embedBuilder.timestamp = DateTime.now();
  embedBuilder.color = DiscordColor.fromHexString("4D346D");
  StringBuffer description = StringBuffer();

  if (result.isEmpty) {
    description.writeln("There are no custom rules configured!");
    description.writeln("Get started with </rules add:1022784407704191009>!");
  } else {
    result.forEach((element) {
      Rule rule = Rule.fromJson(element);
      description.writeln(rule.toString());
    });
  }

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

  EmbedBuilder embedBuilder = EmbedBuilder();
  embedBuilder.timestamp = DateTime.now();

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

  bool success = await storage.insertGuildRule(serverID: interaction.guild_id!, rule: builtRule);
  if (!success) {
    embedBuilder.color = DiscordColor.fromHexString('ff5151');
    embedBuilder.title = "Error!";
    embedBuilder.description = "Your rule could not be created. This is likely because your defined pattern"
        " matches the pattern of an already existing rule.";
  } else {
    embedBuilder.color = DiscordColor.fromHexString('69c273');
    embedBuilder.title = "New Rule Created!";
    embedBuilder.description = descBuffer.toString();
  }

  DiscordHTTP discordHTTP = DiscordHTTP();
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

  EmbedBuilder embedBuilder = EmbedBuilder();
  embedBuilder.timestamp = DateTime.now();

  var result = await storage.removeGuildRule(serverID: interaction.guild_id!, ruleID: ruleID);

  if (!result) {
    embedBuilder.color = DiscordColor.fromHexString('ff5151');
    embedBuilder.title = "Error!";
    embedBuilder.description = "Rule `$ruleID` could not be found.";
  } else {
    embedBuilder.color = DiscordColor.fromHexString('69c273');
    embedBuilder.title = "Success!";
    embedBuilder.description = "Rule `$ruleID` was deleted.";
  }

  DiscordHTTP discordHTTP = DiscordHTTP();
  await discordHTTP.sendFollowupMessage(interactionToken: interaction.token, payload: {
    "embeds": [
      {...embedBuilder.build()}
    ]
  });
}
