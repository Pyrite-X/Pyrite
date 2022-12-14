import '../../structures/rule.dart';
import '../../structures/trigger/trigger_context.dart';
import 'check_result.dart';

import '../../backend/database.dart';

Future<CheckRulesResult> checkRulesList(TriggerContext context) async {
  RuleBuilder ruleBuilder = RuleBuilder();
  RuleQueries db = RuleQueries();
  List<dynamic> serverRuleList = await db.getAllServerRules(context.server.serverID);

  return CheckRulesResult(match: false);
}
