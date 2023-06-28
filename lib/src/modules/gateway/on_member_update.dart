import 'package:nyxx/nyxx.dart';
import 'package:onyx/onyx.dart';

import '../../backend/storage.dart' as storage;
import '../../backend/checks/check.dart' as check;

import '../../structures/trigger/trigger_context.dart';
import '../../structures/trigger/trigger_source.dart';
import '../../structures/server.dart';
import '../../structures/user.dart';

/// Uses the guild member update event to build necessary info.
///
/// Currently unused due to the way Nyxx passes the member object from the event - we'd
/// have to always request the user, which is dumb since all the data we need is given
/// in the event.
///
/// Has a typo in the name too
void om_member_update(IGuildMemberUpdateEvent event) async {
  if (event.user.bot) return;

  Server? server = await storage.fetchGuildData(BigInt.from(event.guild.id.id));
  if (server == null) {
    return;
  }

  TriggerContextBuilder contextBuilder = TriggerContextBuilder()
    ..setEventSource(EventSource(sourceType: EventSourceType.join))
    ..setServer(server);

  IMember member = await event.member.getOrDownload();
  String? nickname = member.nickname;
  String tag = (event.user.discriminator != 0)
      ? "${event.user.username}#${event.user.discriminator}"
      : (event.user.globalName == null)
          ? "@${event.user.username}"
          : "${event.user.globalName} (@${event.user.username})";

  UserBuilder userBuilder = UserBuilder()
    ..setUsername(event.user.username)
    ..setTag(tag)
    ..setGlobalName(event.user.globalName)
    ..setNickname(nickname)
    ..setUserID(BigInt.from(event.user.id.id));

  member.roles.forEach((element) {
    userBuilder.addRole(BigInt.from(element.id.id));
  });

  contextBuilder.setUser(userBuilder.build());
  check.checkUser(contextBuilder.build());
}

/// Currently used way of building the necessary context for Pyrite to
/// be able to check a user on update. Does not require and additional
/// request to Discord to be made.
void on_member_update(JsonData data) async {
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

  check.checkUser(contextBuilder.build());
}
