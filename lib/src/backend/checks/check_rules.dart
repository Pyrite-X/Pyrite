import '../../structures/rule.dart';
import '../../structures/user.dart';
import '../../structures/trigger/trigger_context.dart';
import 'check_result.dart';

import '../../backend/storage.dart' as storage;

Future<CheckRulesResult> checkRulesList(TriggerContext context) async {
  List<Rule> ruleList = context.server.rules;

  if (ruleList.isEmpty) {
    ruleList = await storage.fetchGuildRules(context.server.serverID);
    if (ruleList.isEmpty) {
      return CheckRulesResult(match: false);
    }
  }

  User user = context.user;
  Rule? matchRule;
  String? userString;

  for (Rule rule in ruleList) {
    if (rule.regex) {
      RegExp pattern = RegExp(rule.pattern);
      RegExpMatch? usernameMatch = pattern.firstMatch(user.username);
      RegExpMatch? nicknameMatch;
      if (user.nickname != null) {
        nicknameMatch = pattern.firstMatch(user.nickname!);
      }

      if (usernameMatch != null || nicknameMatch != null) {
        matchRule = rule;
        userString = (usernameMatch != null) ? user.username : user.nickname;
        break;
      }
    } else {
      bool usernameCheck = user.username.toLowerCase() == rule.pattern.toLowerCase();
      bool nicknameCheck = user.nickname?.toLowerCase() == rule.pattern.toLowerCase();
      if (usernameCheck || nicknameCheck) {
        matchRule = rule;
        userString = usernameCheck ? user.username : user.nickname;
        break;
      }
    }
  }

  return (matchRule == null)
      ? CheckRulesResult(match: false)
      : CheckRulesResult(match: true, rule: matchRule, userString: userString);
}
