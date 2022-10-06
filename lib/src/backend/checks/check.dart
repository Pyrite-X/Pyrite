import '../../structures/trigger/trigger_context.dart';
import '../../structures/trigger/trigger_source.dart';

import '../../structures/scan_types.dart';

import '../actions/run_actions.dart';

import 'check_phish_list.dart' as phish;
import 'check_result.dart';
import 'check_rules.dart' as rules;

void checkUser(TriggerContext context) async {
  /// Flow:
  ///   - Get server premium status (when implemented).
  ///   - Utilize event source type to know if the join or scan flow is followed.
  ///
  ///   - On join event flow (aka join):
  ///       - Check phishing list
  ///       - If server owner has premium, check custom rules (if any)
  ///
  ///   - Scan event flow (aka scan):
  ///       - Expect context.eventSource.scanningMode to not be null & not empty
  ///       - Utilize containsType on ScanMode to determine what should be ran
  ///           - Both can run, just individual ifs (not if elses)
  ///
  ///   - If there's a match from the checks, get the action for the server
  ///     (on join action for join flow, phishing list action or rule action for scan flow)
  ///   - Perform actions as they match (kick, ban, log, other combination)
  ///
  ///   - Get actions through containsValue on Action w/ ActionEnum as parameter.

  CheckPhishResult? checkPhishResult;
  CheckRulesResult? checkRulesResult;

  var contextSource = context.eventSource.sourceType;
  if (contextSource == EventSourceType.join) {
    checkPhishResult = phish.checkPhishingList(context);

    // if premium and checkPhishResult has no match, check rules... for now just check rules if no match
    if (!checkPhishResult.match) {
      checkRulesResult = rules.checkRulesList(context);
    }
  }

  if (contextSource == EventSourceType.scan) {
    ScanMode scanningMode = context.eventSource.scanningMode!;

    if (scanningMode.containsType(ScanModeOptions.phish)) {
      checkPhishResult = phish.checkPhishingList(context);
    }

    if (scanningMode.containsType(ScanModeOptions.rules)) {
      checkRulesResult = rules.checkRulesList(context);
    }
  }

  if (checkPhishResult != null && checkPhishResult.match) {
    runActions(context, checkPhishResult);
  }

  if (checkRulesResult != null && checkRulesResult.match) {
    runActions(context, checkRulesResult);
  }
}
