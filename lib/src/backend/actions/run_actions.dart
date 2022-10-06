import '../../structures/trigger/trigger_context.dart';
import '../../structures/trigger/trigger_source.dart';
import '../../structures/action.dart';

import '../checks/check_result.dart';

import 'ban.dart';
import 'kick.dart';
import 'log.dart';

void runActions(TriggerContext context, CheckResult result) async {
  var contextSource = context.eventSource.sourceType;
  if (contextSource == EventSourceType.join) {
    ///TODO: Get server join event action and trigger
  }

  if (contextSource == EventSourceType.scan) {
    if (result is CheckPhishResult) {
      //TODO: get phishing action & follow thru
    } else if (result is CheckRulesResult) {
      Action ruleActions = result.rule!.action;
      triggerActions(ruleActions, context, result);
    }
  }
}

void triggerActions(Action action, TriggerContext context, CheckResult result) {
  if (action.containsValue(ActionEnum.kick.value)) kickUser(context: context);

  if (action.containsValue(ActionEnum.ban.value)) banUser(context: context);

  if (action.containsValue(ActionEnum.log.value)) sendLogMessage(context: context, result: result);
}
