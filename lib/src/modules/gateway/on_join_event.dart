import 'package:nyxx/nyxx.dart';

import '../../backend/checks/check.dart' as check;

import '../../structures/trigger/trigger_context.dart';
import '../../structures/trigger/trigger_source.dart';
import '../../structures/server.dart';
import '../../structures/user.dart';

void on_join_event(IGuildMemberAddEvent event) async {
  //TODO: Check if server has scanning on join enabled first, if not just return to save build time.
  TriggerContextBuilder contextBuilder = TriggerContextBuilder()
    ..setEventSource(EventSource(sourceType: EventSourceType.join));

  UserBuilder userBuilder = UserBuilder()
    ..setUsername(event.user.username)
    ..setNickname(event.member.nickname)
    ..setUserID(BigInt.from(event.user.id.id));

  event.member.roles.forEach((element) {
    userBuilder.addRole(BigInt.from(element.id.id));
  });

  contextBuilder.setUser(userBuilder.build());

  ServerBuilder serverBuilder = ServerBuilder()..setServerID(BigInt.from(event.guild.id.id));

  var guild = await event.guild.getOrDownload();
  serverBuilder.setOwnerID(BigInt.from(guild.owner.id.id));
  contextBuilder.setServer(serverBuilder.build());

  check.checkUser(contextBuilder.build());
}
