import '../../discord_http.dart';

import '../checks/check_result.dart';
import '../../structures/trigger/trigger_context.dart';

void banUser({required TriggerContext context, CheckResult? result}) async {
  String logReason = "";

  if (result is CheckPhishResult) {
    logReason = "User was banned for having a name similar to ${result.matchingString}";
  } else if (result is CheckRulesResult) {
    logReason =
        "User was banned because they matched the pattern ${result.rule!.pattern} on ${result.rule!.ruleID}";
  }

  if (logReason.isEmpty) {
    await DiscordHTTP()
      ..banUser(guildID: context.server.serverID, userID: context.user.userID);
  } else {
    await DiscordHTTP()
      ..banUser(guildID: context.server.serverID, userID: context.user.userID, logReason: logReason);
  }
}
