import '../../structures/rule.dart';
import '../../structures/trigger/trigger_context.dart';
import 'check_result.dart';

import '../../backend/database.dart' as db;

Future<CheckRulesResult> checkRulesList(TriggerContext context) async {
  List<dynamic> serverRuleList = await db.fetchGuildRules(serverID: context.server.serverID);

  return CheckRulesResult(match: false);
}
