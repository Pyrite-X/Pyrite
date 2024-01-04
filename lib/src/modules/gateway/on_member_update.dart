import 'package:onyx/onyx.dart';

import '../../backend/storage.dart' as storage;
import '../../backend/checks/check.dart' as check;

import '../../structures/trigger/trigger_context.dart';
import '../../structures/trigger/trigger_source.dart';
import '../../structures/server.dart';
import '../../structures/user.dart';

/// Currently used way of building the necessary context for Pyrite to
/// be able to check a user on update. Does not require and additional
/// request to Discord to be made.
Future<void> on_member_update(JsonData data) async {
  JsonData userData = data["user"];

  // Ignore if it's a bot that was updated.
  bool bot = userData["bot"] ?? false;
  if (bot) return;

  // Get server config
  BigInt guildID = BigInt.parse(data["guild_id"]);
  Server? server = await storage.fetchGuildData(guildID);
  if (server == null) return;

  // Get user data
  BigInt userID = BigInt.parse(userData["id"]);
  String username = userData["username"];
  int discriminator = int.tryParse(userData["discriminator"]) ?? 0;
  String? globalName = userData["global_name"];
  String? nickname = data["nick"];

  String tag = (discriminator != 0)
      ? "$username#$discriminator"
      : (globalName == null)
          ? "@$username"
          : "$globalName (@$username)";

  List<BigInt> roles = [for (String role in (data["roles"] as List<dynamic>)) BigInt.parse(role)];

  User user = User(
    userID: userID,
    username: username,
    tag: tag,
    globalName: globalName,
    nickname: nickname,
    roles: roles,
  );

  TriggerContextBuilder contextBuilder = TriggerContextBuilder()
    ..setEventSource(EventSource(sourceType: EventSourceType.join))
    ..setServer(server)
    ..setUser(user);

  await check.checkUser(contextBuilder.build());
}
