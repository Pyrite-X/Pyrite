import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:nyxx/nyxx.dart' show EmbedBuilder, Snowflake;
import 'package:onyx/onyx.dart' show JsonData;

import '../../discord_http.dart';

import '../checks/check_result.dart';
import '../../structures/action.dart';
import '../../structures/server.dart';
import '../../structures/user.dart';
import '../../structures/trigger/trigger_context.dart';
import '../../utilities/base_embeds.dart';

void sendLogMessage({required TriggerContext context, required CheckResult result}) async {
  Server guild = context.server;
  User user = context.user;

  BigInt? logchannelID = context.server.logchannelID;
  // Consider complaining somewhere that there is no log channel set?
  if (logchannelID == null) return;

  EmbedBuilder embed = infoEmbed();
  embed.addField(name: "User", content: "<@${user.userID}>", inline: true);

  String title = "";
  if (result.runtimeType == CheckPhishResult) {
    title = "Phishing list match | ${user.tag} ";
    var pma = guild.phishingMatchAction!;
    title = title + _actionToSuffix(pma);

    CheckPhishResult phishResult = result as CheckPhishResult;
    embed.addField(name: "Matching String", content: phishResult.matchingString, inline: true);
  } else if (result.runtimeType == CheckRulesResult) {
    title = "Rule match | ${user.tag}";

    CheckRulesResult checkRulesResult = result as CheckRulesResult;
    var rac = checkRulesResult.rule!.action;
    title = title + _actionToSuffix(rac);

    embed.addField(name: "Rule ID", content: checkRulesResult.rule!.ruleID, inline: true);
    embed.addField(name: "Rule Pattern", content: checkRulesResult.rule!.pattern, inline: true);
  }

  embed.addFooter((footer) {
    footer.text = "User ID: ${user.userID} | Guild ID: ${guild.serverID}";
  });

  DiscordHTTP discordHTTP = DiscordHTTP();
  http.Response userObject = await discordHTTP.getUser(userID: user.userID);
  JsonData userData = json.decode(userObject.body);

  String avatarUrl = "https://cdn.discordapp.com/avatars/${user.userID}/${userData['avatar']}.webp";
  embed.addAuthor((author) {
    author.iconUrl = avatarUrl;
    author.name = title;
  });
  DateTime userCreationDate = Snowflake(user.userID).toSnowflakeEntity().createdAt;
  embed.addField(
      name: "User Join Date",
      content: "${userCreationDate.month}/${userCreationDate.day}/${userCreationDate.year} (mm/dd/yyyy)");

  await discordHTTP.sendLogMessage(channelID: logchannelID, payload: {
    "embeds": [
      {...embed.build()}
    ],
    "allowed_mentions": {"parse": []}
  });
}

String _actionToSuffix(Action action) => action.containsValue(ActionEnum.ban.value)
    ? "| Banned"
    : action.containsValue(ActionEnum.kick.value)
        ? "| Kicked"
        : "| Alert";
