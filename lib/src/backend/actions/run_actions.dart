import '../../structures/trigger/trigger_context.dart';
import '../../structures/trigger/trigger_source.dart';
import '../../structures/action.dart';

import '../checks/check_result.dart';

import 'ban.dart';
import 'kick.dart';
import 'log.dart' as log;

void runActions(TriggerContext context, CheckResult result) async {
  //If batching log msgs someday for scan cmd, need this
  // ignore: unused_local_variable
  var contextSource = context.eventSource.sourceType;

  if (result is CheckPhishResult) {
    Action action = context.server.phishingMatchAction!;
    triggerActions(action, context, result);
  } else if (result is CheckRulesResult) {
    Action ruleActions = result.rule!.action;
    triggerActions(ruleActions, context, result);
  }
}

void triggerActions(Action action, TriggerContext context, CheckResult result) {
  if (action.contains(enumObj: ActionEnum.kick)) kickUser(context: context, result: result);

  if (action.contains(enumObj: ActionEnum.ban)) banUser(context: context, result: result);

  if (action.contains(enumObj: ActionEnum.log)) {
    if (context.eventSource.sourceType == EventSourceType.join) {
      log.sendLogMessage(context: context, result: result);
    } else if (context.eventSource.sourceType == EventSourceType.scan) {
      log.writeScanLog(context: context, result: result);
    }
  }
}
