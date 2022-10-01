import '../../discord_http.dart';

void kickUser({required BigInt userID, required BigInt guildID, required DiscordHTTP httpClient}) async {
  await httpClient.kickUser(guildID: guildID, userID: userID);
}
