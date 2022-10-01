import '../../discord_http.dart';

void banUser({required BigInt userID, required BigInt guildID}) async {
  await DiscordHTTP()
    ..banUser(guildID: guildID, userID: userID);
}
