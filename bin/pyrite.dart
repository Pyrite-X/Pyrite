import 'package:alfred/alfred.dart';
import 'package:dotenv/dotenv.dart';
import 'package:onyx/onyx.dart';
import 'package:pyrite/pyrite.dart' as pyrite;

import 'webserver.dart';

void main(List<String> arguments) {
  var env = DotEnv()..load(['bin/.env']);
  final String publicKey = env["PUB_KEY"]!;

  Onyx onyx = Onyx();
  WebServer server = WebServer(Alfred(), publicKey);
  server.startServer(dispatchFunc: (interaction) => onyx.dispatchInteraction(interaction));
}
