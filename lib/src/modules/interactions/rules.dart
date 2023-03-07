import 'dart:convert';

import 'package:alfred/alfred.dart';
import 'package:nyxx/nyxx.dart' show EmbedBuilder, DiscordColor;
import 'package:onyx/onyx.dart';

import '../../discord_http.dart';
import '../../structures/action.dart';
import '../../structures/rule.dart';
import '../../backend/database.dart' as db;

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

  List<dynamic> result = await db.fetchGuildRules(serverID: interaction.guild_id!);

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
      Rule rule = Rule(
          ruleID: element["ruleID"],
          action: Action.fromInt(element["action"]),
          authorID: BigInt.from(element["authorID"]),
          pattern: element["pattern"],
          regex: element["isRegex"]);

      description.writeln("**Rule ${rule.ruleID}** - <@!${rule.authorID}> (${rule.authorID})");

      description.write("　`Action(s):` ");
      var actionStringList = ActionEnumString.getStringsFromAction(rule.action);
      if (actionStringList.length > 1) {
        /// Can assume this since at most only 2 will ever exist at most. Kick + log, or ban + log.
        description.writeln("${actionStringList.first} + ${actionStringList.last}");
      } else {
        description.writeln(actionStringList.first);
      }

      description.writeln("　`Pattern: `${rule.pattern}");
      description.writeln("　`Regex Matching:` ${rule.regex}");

      if (element["excludedRoles"] != null) {
        description.write("　`Excluded role id(s):` ");
        var excludedRoles = (element["excludedRoles"] as List<dynamic>);
        for (int i = 0; i < excludedRoles.length; i++) {
          description.write("<@&${excludedRoles[i]}>");
          if (i + 1 != excludedRoles.length) {
            description.write(", ");
          } else {
            description.writeln();
          }
        }
      }

      description.writeln();
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

  descBuffer.writeln("**Rule Configuration**");

  options.forEach((element) {
    if (element.name == "pattern") {
      ruleBuilder.setPattern(element.value);
      descBuffer.writeln("　`Pattern:` ${element.value}");
    } else if (element.name == "action") {
      Action action = Action.fromString(element.value);
      ruleBuilder.setAction(action);

      descBuffer.write("　`Action(s):` ");

      var actionStringList = ActionEnumString.getStringsFromAction(action);
      if (actionStringList.length > 1) {
        /// Can assume this since at most only 2 will ever exist at most. Kick + log, or ban + log.
        descBuffer.writeln("${actionStringList.first} + ${actionStringList.last}");
      } else {
        descBuffer.writeln(actionStringList.first);
      }
    } else if (element.name == "regex") {
      ruleBuilder.setRegexFlag(element.value);
      descBuffer.writeln("　`Regex Matching:` ${element.value}");
    }
  });

  embedBuilder.title = "Rule ${ruleBuilder.ruleID} Created!";
  embedBuilder.description = descBuffer.toString();

  await db.insertGuildRule(serverID: interaction.guild_id!, rule: ruleBuilder.build());

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

  var result = await db.removeGuildRule(serverID: interaction.guild_id!, ruleID: ruleID);

  if (!result) {
    embedBuilder.color = DiscordColor.fromHexString('ff5151');
    embedBuilder.title = "Error!";
    embedBuilder.description = "No rule with the ID of `$ruleID` could be found!";
  } else {
    embedBuilder.color = DiscordColor.fromHexString('69c273');
    embedBuilder.title = "Success!";
    embedBuilder.description = "The rule `$ruleID` was deleted!";
  }

  DiscordHTTP discordHTTP = DiscordHTTP();
  await discordHTTP.sendFollowupMessage(interactionToken: interaction.token, payload: {
    "embeds": [
      {...embedBuilder.build()}
    ]
  });
}
