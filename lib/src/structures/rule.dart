import 'package:pyrite/src/structures/action.dart';

class Rule {
  String? ruleID;
  BigInt? authorID;
  bool regex;
  String pattern;
  Action action;
  List<BigInt>? excludedRoles;

  Rule(
      {required this.action,
      required this.pattern,
      required this.regex,
      this.authorID,
      this.excludedRoles,
      this.ruleID});
}

class RuleBuilder {
  late Action action;
  late BigInt authorID;
  List<BigInt> excludedRoles = [];
  late String pattern;
  late bool regex;

  RuleBuilder();

  void addExcludedRole(BigInt roleID) => excludedRoles.add(roleID);
  void setAction(Action action) => this.action = action;
  void setAuthorID(BigInt authorID) => this.authorID = authorID;
  void setPattern(String pattern) => this.pattern = pattern;
  void setRegexFlag(bool flag) => regex = flag;

  Rule build() =>
      Rule(action: action, authorID: authorID, excludedRoles: excludedRoles, pattern: pattern, regex: regex);
}
