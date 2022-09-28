import 'package:alfred/alfred.dart';
import 'package:dotenv/dotenv.dart';
import 'package:onyx/onyx.dart';
import 'package:pyrite/pyrite.dart';

import 'webserver.dart';

void main(List<String> arguments) {
  var env = DotEnv()..load(['bin/.env']);
  final String publicKey = env["PUB_KEY"]!;
  final String token = env["TOKEN"]!;

  Pyrite bot = Pyrite(token: token, publicKey: publicKey);
  bot.startServer();
}
