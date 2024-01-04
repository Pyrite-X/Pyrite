import 'dart:math';

import 'package:onyx/onyx.dart';

import './action.dart';

class Rule {
  late String ruleID;
  late BigInt authorID;
  late String pattern;
  late Action action;
  late bool regex;

  Rule(
      {required this.ruleID,
      required this.action,
      required this.authorID,
      required this.pattern,
      this.regex = false});

  Rule.fromJson(JsonData data) {
    ruleID = data["ruleID"];
    authorID = BigInt.parse(data["authorID"]);
    pattern = data["pattern"];
    action = Action.fromInt(data["action"]);
    regex = data["isRegex"];
  }

  Map<String, dynamic> toJson() => {
        'type': 0,
        'ruleID': ruleID,
        'authorID': authorID.toString(),
        'pattern': pattern,
        'action': action.bitwiseValue,
        'isRegex': regex
      };

  @override
  String toString() {
    StringBuffer buffer = StringBuffer();
    buffer.writeln("**Rule $ruleID** - <@!$authorID> ($authorID)");
    buffer.write("　`Action(s):` ");

    var actionStringList = ActionEnumString.getStringsFromAction(action);
    if (actionStringList.length > 1) {
      /// Can assume this since at most only 2 will ever exist at most. Kick + log, or ban + log.
      buffer.writeln("${actionStringList.first} + ${actionStringList.last}");
    } else {
      buffer.writeln(actionStringList.first);
    }
    buffer.writeln("　`Pattern: `$pattern");
    buffer.writeln("　`Regex Matching:` $regex");

    return buffer.toString();
  }
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
