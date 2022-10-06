import '../../discord_http.dart';

import '../../structures/trigger/trigger_context.dart';

void banUser({required TriggerContext context}) async {
  await DiscordHTTP()
    ..banUser(guildID: context.server.serverID, userID: context.user.userID);
}
