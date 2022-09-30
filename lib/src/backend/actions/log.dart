import 'package:nyxx/nyxx.dart' show EmbedBuilder, DiscordColor;
import '../../structures/action.dart';

void sendLogMessage({required BigInt guildID, required BigInt userID, ActionEnum? actionEnum}) {
  EmbedBuilder embed = EmbedBuilder();
  embed.title = "Match found";

  /// What I think will be included:
  ///   - Username#Tag + Nickname
  ///   - User ID
  ///   - Profile picture
  ///   - Account creation date
  ///   - Maybe account join date?
  ///
  ///   - Probably add an unban button too
}
