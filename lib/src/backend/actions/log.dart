import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:nyxx/nyxx.dart' show EmbedBuilder;
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

  dynamic typedResult =
      result.runtimeType == CheckPhishResult ? result as CheckPhishResult : result as CheckRulesResult;

  BigInt? logchannelID = context.server.logchannelID;
  // Consider complaining somewhere that there is no log channel set?
  if (logchannelID == null) return;

  EmbedBuilder embed = infoEmbed();

  DiscordHTTP discordHTTP = DiscordHTTP();
  http.Response userObject = await discordHTTP.getUser(userID: user.userID);
  JsonData userData = json.decode(userObject.body);

  embed.addField(
      name: "User",
      content: "<@${user.userID}>\n"
          "**Name**: ${typedResult.userString}",
      inline: true);

  String title = "";
  if (result.runtimeType == CheckPhishResult) {
    var pma = guild.phishingMatchAction!;
    title = "Bot List Match | ${_actionToSuffix(pma)} | ${user.tag} ";

    embed.addField(
        name: "Match",
        content: "**Name**: ${typedResult.matchingString}\n"
            "**Percentage**: ~${typedResult.fuzzyMatchPercent?.toStringAsPrecision(4)}%",
        inline: true);
  } else if (result.runtimeType == CheckRulesResult) {
    var rac = typedResult.rule!.action;
    title = "Rule Match | ${_actionToSuffix(rac)}| ${user.tag}";

    embed.addField(
        name: "Rule",
        content: "**ID**: ${typedResult.rule!.ruleID}\n**Pattern**: ${typedResult.rule!.pattern}",
        inline: true);
  }

  embed.addFooter((footer) {
    footer.text = "User ID: ${user.userID}";
  });

  String avatarUrl = "https://cdn.discordapp.com/avatars/${user.userID}/${userData['avatar']}.webp";
  embed.addAuthor((author) {
    author.iconUrl = avatarUrl;
    author.name = title;
  });

  http.Response msgResponse = await discordHTTP.sendMessage(channelID: logchannelID, payload: {
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
