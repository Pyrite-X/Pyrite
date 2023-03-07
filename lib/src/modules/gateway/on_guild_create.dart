import 'package:nyxx/nyxx.dart';

import '../../backend/database.dart';

void on_guild_create(IGuildCreateEvent event) async {
  print("Guild create event: ${event.guild.name} owned by ${event.guild.owner.id}");
  await fetchGuildData(serverID: BigInt.from(event.guild.id.id), generateOnNull: true);
}
