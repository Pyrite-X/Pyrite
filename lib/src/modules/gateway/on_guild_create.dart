import 'package:logging/logging.dart';
import 'package:nyxx/nyxx.dart';

import '../../backend/database.dart' as db;

Logger _logger = Logger("Guild Create");
void on_guild_create(IGuildCreateEvent event) async {
  _logger.info("Joined guild \"${event.guild.name}\" (${event.guild.id}), owner: ${event.guild.owner.id}");

  await db.insertNewGuild(serverID: BigInt.from(event.guild.id.id));
}
