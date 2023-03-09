import '../../structures/rule.dart';

abstract class CheckResult {
  bool match;

  CheckResult({required this.match});
}

class CheckPhishResult extends CheckResult {
  String? matchingString;
  double? fuzzyMatchPercent;

  CheckPhishResult({required super.match, this.matchingString, this.fuzzyMatchPercent});
}

class CheckRulesResult extends CheckResult {
  Rule? rule;

  CheckRulesResult({required super.match, this.rule});
}
