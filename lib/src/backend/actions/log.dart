import 'package:nyxx/nyxx.dart' show EmbedBuilder, DiscordColor;

import '../../structures/action.dart';
import '../../discord_http.dart';

void sendLogMessage(
    {required BigInt channelID,
    required BigInt userID,
    required DiscordHTTP httpClient,
    ActionEnum? actionEnum}) async {
  EmbedBuilder embed = EmbedBuilder();
  embed.title = "Match found";
  embed.color = DiscordColor.fromHexString("4D346D");

  await httpClient.sendLogMessage(channelID: channelID, payload: {
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
