import 'package:nyxx/nyxx.dart';

import '../../backend/storage.dart' as storage;
import '../../backend/checks/check.dart' as check;

import '../../structures/trigger/trigger_context.dart';
import '../../structures/trigger/trigger_source.dart';
import '../../structures/server.dart';
import '../../structures/user.dart';

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
  UserBuilder userBuilder = UserBuilder()
    ..setUsername(event.user.username)
    ..setTag(event.user.tag)
    // ..setGlobalName()
    ..setNickname(nickname)
    ..setUserID(BigInt.from(event.user.id.id));

  member.roles.forEach((element) {
    userBuilder.addRole(BigInt.from(element.id.id));
  });

  contextBuilder.setUser(userBuilder.build());
  check.checkUser(contextBuilder.build());
}
