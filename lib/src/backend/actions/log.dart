import 'package:nyxx/nyxx.dart' show EmbedBuilder, DiscordColor;

import '../../discord_http.dart';

import '../checks/check_result.dart';
import '../../structures/trigger/trigger_context.dart';

void sendLogMessage({required TriggerContext context, required CheckResult result}) async {
  EmbedBuilder embed = EmbedBuilder();
  embed.title = "Match found";
  embed.color = DiscordColor.fromHexString("4D346D");

  //TODO: Get server channel to send message to based on id in context.

  await DiscordHTTP()
    ..sendLogMessage(channelID: BigInt.zero, payload: {
      "embeds": [
        {...embed.build()}
      ]
    });

  /// What I think will be included:
  ///   - Username#Tag + Nickname
  ///   - User ID
  ///   - Profile picture
  ///   - Account creation date
  ///   - Maybe account join date?
  ///
  ///   - Probably add an unban button too
}
