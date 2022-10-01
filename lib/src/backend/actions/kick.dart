import '../../discord_http.dart';

void kickUser({required BigInt userID, required BigInt guildID}) async {
  await DiscordHTTP()
    ..kickUser(guildID: guildID, userID: userID);
}
