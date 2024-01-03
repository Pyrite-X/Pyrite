import 'package:nyxx/nyxx.dart' as nyxx;

import '../../backend/storage.dart' as storage;
import '../../backend/checks/check.dart' as check;

import '../../structures/trigger/trigger_context.dart';
import '../../structures/trigger/trigger_source.dart';
import '../../structures/server.dart';
import '../../structures/user.dart';

void on_join_event(nyxx.GuildMemberAddEvent event) async {
  nyxx.User nyxxUser = event.member.user!;

  if (nyxxUser.isBot) return;

  Server? server = await storage.fetchGuildData(BigInt.from(event.guild.id.value));
  if (server == null || (server.onJoinEnabled != null && !server.onJoinEnabled!)) {
    return;
  }

  TriggerContextBuilder contextBuilder = TriggerContextBuilder()
    ..setEventSource(EventSource(sourceType: EventSourceType.join))
    ..setServer(server);

  String tag = (nyxxUser.discriminator != 0)
      ? "${nyxxUser.username}#${nyxxUser.discriminator}"
      : (nyxxUser.globalName == null)
          ? "@${nyxxUser.username}"
          : "${nyxxUser.globalName} (@${nyxxUser.username})";

  UserBuilder userBuilder = UserBuilder()
    ..setUsername(nyxxUser.username)
    ..setTag(tag)
    ..setGlobalName(nyxxUser.globalName)
    ..setNickname(event.member.nick)
    ..setUserID(BigInt.from(nyxxUser.id.value));

  /// Really, they shouldn't have any roles on join so this rather
  /// pointless, but I'll leave it in in case for some reason it happens.
  event.member.roles.forEach((element) {
    userBuilder.addRole(BigInt.from(element.id.value));
  });

  contextBuilder.setUser(userBuilder.build());
  check.checkUser(contextBuilder.build());
}
