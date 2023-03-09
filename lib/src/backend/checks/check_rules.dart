import '../../structures/rule.dart';
import '../../structures/user.dart';
import '../../structures/trigger/trigger_context.dart';
import 'check_result.dart';

import '../../backend/storage.dart' as storage;

Future<CheckRulesResult> checkRulesList(TriggerContext context) async {
  List<Rule> ruleList = context.server.rules;
  if (context.server.rules.isEmpty) {
    context.server.rules = await storage.fetchGuildRules(context.server.serverID);
    if (context.server.rules.isEmpty) {
      return CheckRulesResult(match: false);
    }
  }

  User user = context.user;
  Rule? matchRule;
  for (Rule rule in ruleList) {
    if (rule.regex) {
      RegExp pattern = RegExp(rule.pattern);
      RegExpMatch? usernameMatch = pattern.firstMatch(user.username);
      RegExpMatch? nicknameMatch = pattern.firstMatch(user.nickname!.toString());
      if (usernameMatch != null || nicknameMatch != null) {
        matchRule = rule;
        break;
      }
    } else {
      bool usernameCheck = user.username.toLowerCase() == rule.pattern.toLowerCase();
      bool nicknameCheck = user.nickname?.toLowerCase() == rule.pattern.toLowerCase();
      if (usernameCheck || nicknameCheck) {
        matchRule = rule;
        break;
      }
    }
  }

  return (matchRule == null)
      ? CheckRulesResult(match: false)
      : CheckRulesResult(match: true, rule: matchRule);
}
