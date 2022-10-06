import '../../discord_http.dart';

import '../../structures/trigger/trigger_context.dart';

void kickUser({required TriggerContext context}) async {
  await DiscordHTTP()
    ..kickUser(guildID: context.server.serverID, userID: context.user.userID);
}
