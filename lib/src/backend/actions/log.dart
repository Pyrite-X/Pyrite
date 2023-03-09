import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:nyxx/nyxx.dart' show EmbedBuilder, Snowflake;
import 'package:onyx/onyx.dart' show JsonData;

import '../storage.dart' as storage;
import '../checks/check_result.dart';
import '../../discord_http.dart';
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
    title = "Phishing List Match | ${user.tag} ";
    var pma = guild.phishingMatchAction!;
    embed.addField(name: "Action", content: _actionToSuffix(pma), inline: true);

    CheckPhishResult phishResult = result as CheckPhishResult;
    embed.addField(name: "Matching String", content: phishResult.matchingString, inline: true);

    embed.addField(
        name: "Match Percentage",
        content: "~${phishResult.fuzzyMatchPercent?.toStringAsPrecision(4)}%",
        inline: true);
  } else if (result.runtimeType == CheckRulesResult) {
    title = "Rule match | ${user.tag}";

    CheckRulesResult checkRulesResult = result as CheckRulesResult;
    var rac = checkRulesResult.rule!.action;
    embed.addField(name: "Action", content: _actionToSuffix(rac), inline: true);

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
      content: "<t:${(userCreationDate.millisecondsSinceEpoch / 1000).round()}:D>",
      inline: true);

  http.Response msgResponse = await discordHTTP.sendLogMessage(channelID: logchannelID, payload: {
    "embeds": [
      {...embed.build()}
    ],
    "allowed_mentions": {"parse": []}
  });
  if (msgResponse.statusCode == 403 || msgResponse.statusCode == 404) {
    storage.removeGuildField(serverID: guild.serverID, fieldName: "logchannelID");
  }
}

String _actionToSuffix(Action action) => action.containsValue(ActionEnum.ban.value)
    ? "Banned"
    : action.containsValue(ActionEnum.kick.value)
        ? "Kicked"
        : "Alert";
