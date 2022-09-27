import 'package:alfred/alfred.dart';
import 'package:onyx/onyx.dart';

import 'src/backend/webserver.dart';

class Pyrite {
  final String token;
  final String publicKey;
  late final Onyx onyx;

  Pyrite({required this.token, required this.publicKey}) {
    onyx = Onyx();
  }

  void startGateway() async {}

  void startServer() async {
    WebServer server = WebServer(Alfred(), publicKey);
    server.startServer(dispatchFunc: onyx.dispatchInteraction);
  }
}
