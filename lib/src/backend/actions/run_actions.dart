import 'dart:async';

import '../../structures/trigger/trigger_context.dart';
import '../../structures/trigger/trigger_source.dart';
import '../../structures/action.dart';

import '../checks/check_result.dart';

import 'ban.dart';
import 'kick.dart';
import 'log.dart' as log;

Future<void> runActions(TriggerContext context, CheckResult result) async {
  //If batching log msgs someday for scan cmd, need this
  // ignore: unused_local_variable
  var contextSource = context.eventSource.sourceType;

  Action action = (result is CheckPhishResult)
      ? context.server.phishingMatchAction!
      : (result as CheckRulesResult).rule!.action;

  await triggerActions(action, context, result);
}

Future<void> triggerActions(Action action, TriggerContext context, CheckResult result) async {
  if (action.contains(enumObj: ActionEnum.kick)) await kickUser(context: context, result: result);

  if (action.contains(enumObj: ActionEnum.ban)) await banUser(context: context, result: result);

  if (action.contains(enumObj: ActionEnum.log)) {
    if (context.eventSource.sourceType == EventSourceType.join) {
      await log.sendLogMessage(context: context, result: result);
    } else if (context.eventSource.sourceType == EventSourceType.scan) {
      await log.writeScanLog(context: context, result: result);
    }
  }
}
