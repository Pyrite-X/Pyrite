import 'dart:math';

import './action.dart';

class Rule {
  String ruleID;
  BigInt authorID;
  bool regex;
  String pattern;
  Action action;

  Rule(
      {required this.ruleID,
      required this.action,
      required this.authorID,
      required this.pattern,
      this.regex = false});
}

class RuleBuilder {
  late String ruleID;
  late Action action;
  late BigInt authorID;
  late String pattern;
  bool regex = false;

  RuleBuilder();

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

  Rule build() => Rule(ruleID: ruleID, action: action, authorID: authorID, pattern: pattern, regex: regex);
}
