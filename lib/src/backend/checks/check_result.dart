import '../../structures/rule.dart';

abstract class CheckResult {
  bool match;

  CheckResult(this.match);
}

class CheckPhishResult implements CheckResult {
  String? matchingString;
  bool match;

  CheckPhishResult({required this.match, this.matchingString});
}

class CheckRulesResult implements CheckResult {
  Rule? rule;
  bool match;

  CheckRulesResult({required this.match, this.rule});
}
