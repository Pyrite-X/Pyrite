import '../../discord_http.dart';

import '../checks/check_result.dart';
import '../../structures/trigger/trigger_context.dart';

void kickUser({required TriggerContext context, CheckResult? result}) async {
  String logReason = "";

  if (result is CheckPhishResult) {
    logReason = "User was kicked for having a name similar to ${result.matchingString}";
  } else if (result is CheckRulesResult) {
    logReason =
        "User was kicked because they matched the pattern ${result.rule!.pattern} on ${result.rule!.ruleID}";
  }

  if (logReason.isEmpty) {
    await DiscordHTTP()
      ..kickUser(guildID: context.server.serverID, userID: context.user.userID);
  } else {
    await DiscordHTTP()
      ..kickUser(guildID: context.server.serverID, userID: context.user.userID, logReason: logReason);
  }
}
