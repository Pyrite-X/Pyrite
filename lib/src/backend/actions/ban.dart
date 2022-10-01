import '../../discord_http.dart';

void banUser({required BigInt userID, required BigInt guildID, required DiscordHTTP httpClient}) async {
  await httpClient.banUser(guildID: guildID, userID: userID);
}
