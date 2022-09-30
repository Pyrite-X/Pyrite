import 'package:pyrite/src/structures/action.dart';

class Rule {
  int? ruleID;
  bool regex;
  String pattern;
  Action action;
  BigInt? excludeRole;

  Rule({required this.pattern, required this.action, required this.regex, this.ruleID, this.excludeRole});
}

class RuleBuilder {
  late bool regex;
  late String pattern;
  late Action action;
  late BigInt excludeRole;

  RuleBuilder();

  void setAction(Action action) => this.action = action;
  void setExcludeRole(BigInt roleID) => excludeRole = roleID;
  void setPattern(String pattern) => this.pattern = pattern;
  void setRegexFlag(bool flag) => regex = flag;

  Rule build() => Rule(pattern: pattern, action: action, regex: regex, excludeRole: excludeRole);
}
