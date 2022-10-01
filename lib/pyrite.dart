import 'package:alfred/alfred.dart';
import 'package:nyxx/nyxx.dart';
import 'package:onyx/onyx.dart';

import 'src/discord_http.dart';

import 'src/backend/webserver.dart';

import 'src/modules/gateway/on_join_event.dart' as on_join_event;

import 'src/modules/interactions/about.dart' as about;
import 'src/modules/interactions/config.dart' as config;
import 'src/modules/interactions/help.dart' as help;
import 'src/modules/interactions/redeem.dart' as redeem;
import 'src/modules/interactions/rules.dart' as rules;
import 'src/modules/interactions/scan.dart' as scan;
import 'src/modules/interactions/transfer.dart' as transfer;

class Pyrite {
  final String token;
  final String publicKey;
  final BigInt appID;
  final DiscordHTTP restClient;
  late final Onyx onyx;
  late final INyxxWebsocket gateway;

  Pyrite({required this.token, required this.publicKey, required this.appID, required this.restClient});

  void startGateway() async {
    gateway = NyxxFactory.createNyxxWebsocket(token, GatewayIntents.guildMembers)
      ..registerPlugin(Logging())
      ..registerPlugin(CliIntegration());

    gateway.eventsWs.onGuildMemberAdd.listen((event) => on_join_event.on_join_event(event));
    gateway.eventsWs.onGuildMemberUpdate.listen((event) async {
      print((await event.member.getOrDownload()).nickname);
      print(event.user.username);
    });

    gateway.eventsWs.onReady.listen((event) {
      gateway.setPresence(PresenceBuilder.of(
          status: UserStatus.idle,
          activity: ActivityBuilder("for suspicious users...", ActivityType.watching)));
    });

    await gateway.connect();
  }

  void startServer() async {
    onyx = Onyx();
    onyx.registerAppCommandHandler("about", about.aboutCmd);
    onyx.registerAppCommandHandler("config", config.configCmd);
    onyx.registerAppCommandHandler("help", help.helpCmd);
    onyx.registerAppCommandHandler("redeem", redeem.redeemCmd);
    onyx.registerAppCommandHandler("rules", rules.rulesCmd);
    onyx.registerAppCommandHandler("scan", scan.scanCmd);
    onyx.registerAppCommandHandler("transfer", transfer.transferCmd);

    WebServer server = WebServer(Alfred(), publicKey);
    server.startServer(dispatchFunc: ((p0) {
      var currentMetadata = p0.metadata;
      Map<String, dynamic> newMetadata = {"request": currentMetadata, "pyrite": this};

      p0.setMetadata(newMetadata);
      onyx.dispatchInteraction(p0);
    }));
  }
}
