import '../../structures/trigger/trigger_context.dart';
import '../../structures/trigger/trigger_source.dart';

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
}
