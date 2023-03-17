import '../../discord_http.dart';

import '../checks/check_result.dart';
import '../../structures/trigger/trigger_context.dart';

void kickUser({required TriggerContext context, CheckResult? result}) async {
  String logReason = "";
  var user = context.user;

  if (result is CheckPhishResult) {
    String percentage =
        (result.fuzzyMatchPercent == 100) ? "100" : result.fuzzyMatchPercent!.toStringAsPrecision(4);
    logReason = "${user.tag} (${user.userID}) - "
        "Username/Nickname matched \"${result.matchingString}\" from the bot list "
        "as a ~$percentage% match.";
  } else if (result is CheckRulesResult) {
    logReason = "${user.tag} (${user.userID}) - "
        "Username/Nickname matched Rule \"${result.rule!.ruleID}\" with "
        "the pattern ${result.rule!.pattern}.";
  }

  if (logReason.isEmpty) {
    await DiscordHTTP()
      ..kickUser(guildID: context.server.serverID, userID: context.user.userID);
  } else {
    await DiscordHTTP()
      ..kickUser(guildID: context.server.serverID, userID: context.user.userID, logReason: logReason);
  }
}
