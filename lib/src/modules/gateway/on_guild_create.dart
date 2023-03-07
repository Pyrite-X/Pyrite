import 'package:nyxx/nyxx.dart';

import '../../backend/database.dart' as db;

void on_guild_create(IGuildCreateEvent event) async {
  print("Guild create event: ${event.guild.name} owned by ${event.guild.owner.id}");
  await db.insertNewGuild(serverID: BigInt.from(event.guild.id.id));
}
