import 'package:logging/logging.dart';
import 'package:nyxx/nyxx.dart';

import '../../backend/database.dart' as db;

Logger _logger = Logger("Guild Create");
Future<void> on_guild_create(UnavailableGuildCreateEvent event) async {
  if (event is GuildCreateEvent) {
    _logger.info("Joined guild \"${event.guild.name}\" (${event.guild.id}), owner: ${event.guild.owner.id}");
  } else {
    _logger.info("Joined unavailable guild ${event.guild.id}");
  }

  await db.insertNewGuild(serverID: BigInt.from(event.guild.id.value));
}
