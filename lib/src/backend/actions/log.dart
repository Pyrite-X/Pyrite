import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:nyxx/nyxx.dart' show EmbedBuilder, EmbedFieldBuilder, EmbedFooterBuilder, EmbedAuthorBuilder;
import 'package:onyx/onyx.dart';

import '../storage.dart' as storage;
import '../checks/check_result.dart';
import '../../discord_http.dart';
import '../../structures/action.dart';
import '../../structures/server.dart';
import '../../structures/user.dart';
import '../../structures/trigger/trigger_context.dart';
import '../../utilities/base_embeds.dart';

Logger _logger = Logger("Action Log");

void sendLogMessage({required TriggerContext context, required CheckResult result}) async {
  Server guild = context.server;
  User user = context.user;

  dynamic typedResult =
      result.runtimeType == CheckPhishResult ? result as CheckPhishResult : result as CheckRulesResult;

  _logger.info("${user.tag} (${user.userID}) logged a match in ${context.server.serverID} "
      "with their ${typedResult.nameStringType}: ${typedResult.userString}");

  BigInt? logchannelID = context.server.logchannelID;
  // Consider complaining somewhere that there is no log channel set?
  if (logchannelID == null) return;

  EmbedBuilder embed = infoEmbed();

  DiscordHTTP discordHTTP = DiscordHTTP();
  http.Response userObject = await discordHTTP.getUser(userID: user.userID);
  JsonData userData = json.decode(userObject.body);

  embed.fields!.add(EmbedFieldBuilder(
      name: "User",
      value: "<@${user.userID}>\n"
          "**${typedResult.nameStringType}**: ${typedResult.userString}",
      isInline: true));

  String title = "";
  ActionRow? actionRow;

  if (result.runtimeType == CheckPhishResult) {
    var pma = guild.phishingMatchAction!;
    title = "Bot List Match | ${_actionToSuffix(pma)} | ${user.tag} ";

    actionRow = _buildEmbedButtons(pma, user.userID, typedResult.userString);

    String percentage = (typedResult.fuzzyMatchPercent == 100)
        ? "100"
        : typedResult.fuzzyMatchPercent?.toStringAsPrecision(4);

    embed.fields!.add(EmbedFieldBuilder(
        name: "Match",
        value: "**Name**: ${typedResult.matchingString}\n"
            "**Percentage**: ~$percentage%",
        isInline: true));
  } else if (result.runtimeType == CheckRulesResult) {
    var rac = typedResult.rule!.action;
    title = "Rule Match | ${_actionToSuffix(rac)} | ${user.tag}";

    actionRow = _buildEmbedButtons(rac, user.userID, typedResult.userString);

    embed.fields!.add(EmbedFieldBuilder(
        name: "Rule",
        value: "**ID**: ${typedResult.rule!.ruleID}\n**Pattern**: ${typedResult.rule!.pattern}",
        isInline: true));
  }

  embed.footer = EmbedFooterBuilder(text: "User ID: ${user.userID}");

  String avatarUrl = "https://cdn.discordapp.com/avatars/${user.userID}/${userData['avatar']}.webp";
  embed.author = EmbedAuthorBuilder(name: title, iconUrl: Uri.parse(avatarUrl));

  http.Response msgResponse = await discordHTTP.sendMessage(channelID: logchannelID, payload: {
    "embeds": [
      {...embed.build()}
    ],
    "allowed_mentions": {"parse": []},
    "components": [
      {...actionRow!.toJson()}
    ]
  });

  if (msgResponse.statusCode == 403 || msgResponse.statusCode == 404) {
    storage.removeGuildField(serverID: guild.serverID, fieldName: "logchannelID");
  }
}

ActionRow _buildEmbedButtons(Action action, BigInt userID, String userString) {
  // Only include if the action didn't kick or ban the user already.
  bool includeModerationButtons =
      !(action.contains(enumObj: ActionEnum.ban) || action.contains(enumObj: ActionEnum.kick));
  ActionRow actionRow = ActionRow();

  actionRow.addComponent(
      Button(style: ButtonStyle.primary, label: "User info", custom_id: "log_button:info:$userID"));

  actionRow.addComponent(Button(
      style: ButtonStyle.secondary, label: "Whitelist name", custom_id: "log_button:whitelist:$userString"));

  if (includeModerationButtons) {
    actionRow.addComponent(
        Button(style: ButtonStyle.secondary, label: "Kick user", custom_id: "log_button:kick:$userID"));
    actionRow.addComponent(
        Button(style: ButtonStyle.secondary, label: "Ban user", custom_id: "log_button:ban:$userID"));
  }

  return actionRow;
}

// VVVVVV ---------------- Scan Log logic ---------------- VVVVVV

Map<BigInt, StringBuffer> logBufferMap = {};

Future<void> writeScanLog({required TriggerContext context, required CheckResult result}) async {
  Server guild = context.server;
  User user = context.user;

  dynamic typedResult =
      result.runtimeType == CheckPhishResult ? result as CheckPhishResult : result as CheckRulesResult;

  StringBuffer sb = logBufferMap.putIfAbsent(context.server.serverID, () => StringBuffer());

  if (typedResult is CheckPhishResult) {
    var action = guild.phishingMatchAction!;
    String percentage = (typedResult.fuzzyMatchPercent == 100)
        ? "100"
        : typedResult.fuzzyMatchPercent!.toStringAsPrecision(4);

    sb.writeln("${_actionToSuffix(action)}: ${user.tag} (${user.userID}) - "
        "This user's ${typedResult.nameStringType!.toLowerCase()} (\"${typedResult.userString}\") matched "
        "\"${typedResult.matchingString}\" from the bot list "
        "as a ~$percentage% match.");
  } else if (typedResult is CheckRulesResult) {
    var action = typedResult.rule!.action;

    sb.writeln("${_actionToSuffix(action)}: ${user.tag} (${user.userID}) - "
        "This user's ${typedResult.nameStringType!.toLowerCase()} \"(${typedResult.userString})\" matched "
        "Rule \"${typedResult.rule!.ruleID}\" with "
        "the pattern ${typedResult.rule!.pattern}.");
  }

  _logger.info("${user.tag} (${user.userID}) logged a match in ${context.server.serverID} "
      "with their ${typedResult.nameStringType}: ${typedResult.userString}");
}

String dumpServerScanLog({required BigInt serverID}) {
  StringBuffer? outputBuffer = logBufferMap[serverID];
  String output = "";
  if (outputBuffer != null) {
    output = outputBuffer.toString();
  }

  logBufferMap.remove(serverID);
  return output;
}

String _actionToSuffix(Action action) => action.contains(enumObj: ActionEnum.ban)
    ? "Banned"
    : action.contains(enumObj: ActionEnum.kick)
        ? "Kicked"
        : "Alert";
