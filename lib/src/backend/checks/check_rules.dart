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

  bool usernameCheck = false;
  bool globalNameCheck = false;
  bool nicknameCheck = false;

  for (Rule rule in ruleList) {
    if (rule.regex) {
      RegExp pattern = RegExp(rule.pattern);
      RegExpMatch? usernameMatch = pattern.firstMatch(user.username);

      RegExpMatch? globalNameMatch;
      if (user.globalName != null) {
        globalNameMatch = pattern.firstMatch(user.globalName!);
      }

      RegExpMatch? nicknameMatch;
      if (user.nickname != null) {
        nicknameMatch = pattern.firstMatch(user.nickname!);
      }

      if (usernameMatch != null || globalNameMatch != null || nicknameMatch != null) {
        matchRule = rule;
        userString = (usernameMatch != null)
            ? user.username
            : (globalNameMatch != null)
                ? user.globalName
                : user.nickname;

        if (usernameMatch != null)
          usernameCheck = true;
        else if (globalNameMatch != null)
          globalNameCheck = true;
        else if (nicknameMatch != null) nicknameCheck = true;

        break;
      }
    } else {
      usernameCheck = user.username.toLowerCase() == rule.pattern.toLowerCase();
      nicknameCheck = user.nickname?.toLowerCase() == rule.pattern.toLowerCase();
      globalNameCheck = user.globalName?.toLowerCase() == rule.pattern.toLowerCase();

      if (usernameCheck || nicknameCheck || globalNameCheck) {
        matchRule = rule;
        userString = usernameCheck
            ? user.username
            : nicknameCheck
                ? user.nickname
                : user.globalName;

        break;
      }
    }
  }

  String? nameStringType = null;
  if (usernameCheck)
    nameStringType = "Username";
  else if (globalNameCheck)
    nameStringType = "Display Name";
  else if (nicknameCheck) nameStringType = "Nickname";

  return (matchRule == null)
      ? CheckRulesResult(match: false)
      : CheckRulesResult(
          match: true,
          nameStringType: nameStringType,
          rule: matchRule,
          userString: userString,
        );
}
