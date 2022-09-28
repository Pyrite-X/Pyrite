import 'package:alfred/alfred.dart';
import 'package:onyx/onyx.dart';

import 'src/backend/webserver.dart';

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
  late final Onyx onyx;

  Pyrite({required this.token, required this.publicKey}) {
    onyx = Onyx();
    onyx.registerAppCommandHandler("about", about.aboutCmd);
  }

  void startGateway() async {}

  void startServer() async {
    WebServer server = WebServer(Alfred(), publicKey);
    server.startServer(dispatchFunc: onyx.dispatchInteraction);
  }
}
