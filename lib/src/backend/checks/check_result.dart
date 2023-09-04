import '../../structures/rule.dart';

abstract class CheckResult {
  /// Was this a match or not
  bool match;

  /// Type of the name that was matched (display name, global name, nickname)
  String? nameStringType;

  CheckResult({required this.match, this.nameStringType});
}

class CheckPhishResult extends CheckResult {
  String? matchingString;
  String? userString;
  double? fuzzyMatchPercent;

  CheckPhishResult(
      {required super.match,
      super.nameStringType,
      this.matchingString,
      this.fuzzyMatchPercent,
      this.userString});
}

class CheckRulesResult extends CheckResult {
  Rule? rule;
  String? userString;

  CheckRulesResult({required super.match, super.nameStringType, this.rule, this.userString});
}
