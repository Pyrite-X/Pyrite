import 'dart:math';

import './action.dart';

class Rule {
  String ruleID;
  BigInt authorID;
  bool regex;
  String pattern;
  Action action;
  List<BigInt>? excludedRoles;

  Rule(
      {required this.ruleID,
      required this.action,
      required this.authorID,
      required this.pattern,
      this.regex = false,
      this.excludedRoles});
}

class RuleBuilder {
  late String ruleID;
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

  void setRuleID(String ruleID) => this.ruleID = ruleID;
  void generateRuleID() {
    var elements = List<String>.generate(4, (index) => Random.secure().nextInt(256).toRadixString(16));
    StringBuffer stringBuffer = StringBuffer();
    elements.forEach((element) {
      stringBuffer.write(element);
    });
    ruleID = stringBuffer.toString();
  }

  Rule build() => Rule(
      ruleID: ruleID,
      action: action,
      authorID: authorID,
      excludedRoles: excludedRoles,
      pattern: pattern,
      regex: regex);
}
