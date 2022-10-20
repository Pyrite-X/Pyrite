import 'package:pyrite/src/structures/action.dart';

class Rule {
  String? ruleID;
  bool regex;
  String pattern;
  Action action;
  List<BigInt>? excludedRoles;

  Rule({required this.pattern, required this.action, required this.regex, this.ruleID, this.excludedRoles});
}

class RuleBuilder {
  late bool regex;
  late String pattern;
  late Action action;
  List<BigInt> excludedRoles = [];

  RuleBuilder();

  void setAction(Action action) => this.action = action;
  void addExcludedRole(BigInt roleID) => excludedRoles.add(roleID);
  void setPattern(String pattern) => this.pattern = pattern;
  void setRegexFlag(bool flag) => regex = flag;

  Rule build() => Rule(pattern: pattern, action: action, regex: regex, excludedRoles: excludedRoles);
}
