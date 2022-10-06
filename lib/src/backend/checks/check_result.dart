import '../../structures/rule.dart';

abstract class CheckResult {
  bool match;

  CheckResult({required this.match});
}

class CheckPhishResult extends CheckResult {
  String? matchingString;

  CheckPhishResult({required super.match, this.matchingString});
}

class CheckRulesResult extends CheckResult {
  Rule? rule;

  CheckRulesResult({required super.match, this.rule});
}
