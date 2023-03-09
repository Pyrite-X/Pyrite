import 'package:nyxx/nyxx.dart';

import '../../backend/storage.dart' as storage;
import '../../backend/checks/check.dart' as check;

import '../../structures/trigger/trigger_context.dart';
import '../../structures/trigger/trigger_source.dart';
import '../../structures/server.dart';
import '../../structures/user.dart';

void on_join_event(IGuildMemberAddEvent event) async {
  if (event.user.bot) return;

  Server? server = await storage.fetchGuildData(BigInt.from(event.guild.id.id));
  if (server == null || (server.onJoinEnabled != null && !server.onJoinEnabled!)) {
    return;
  }

  TriggerContextBuilder contextBuilder = TriggerContextBuilder()
    ..setEventSource(EventSource(sourceType: EventSourceType.join))
    ..setServer(server);

  UserBuilder userBuilder = UserBuilder()
    ..setUsername(event.user.username)
    ..setNickname(event.member.nickname)
    ..setUserID(BigInt.from(event.user.id.id));

  /// Really, they shouldn't have any roles on join so this rather
  /// pointless, but I'll leave it in in case for some reason it happens.
  event.member.roles.forEach((element) {
    userBuilder.addRole(BigInt.from(element.id.id));
  });

  contextBuilder.setUser(userBuilder.build());
  check.checkUser(contextBuilder.build());
}
