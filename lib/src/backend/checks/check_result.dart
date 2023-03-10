import '../../structures/rule.dart';

abstract class CheckResult {
  bool match;

  CheckResult({required this.match});
}

class CheckPhishResult extends CheckResult {
  String? matchingString;
  String? userString;
  double? fuzzyMatchPercent;

  CheckPhishResult({required super.match, this.matchingString, this.fuzzyMatchPercent, this.userString});
}

class CheckRulesResult extends CheckResult {
  Rule? rule;
  String? userString;

  CheckRulesResult({required super.match, this.rule, this.userString});
}
