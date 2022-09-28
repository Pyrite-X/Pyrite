import 'package:dotenv/dotenv.dart';
import 'package:pyrite/pyrite.dart';

void main(List<String> arguments) {
  var env = DotEnv()..load(['bin/.env']);
  final String publicKey = env["PUB_KEY"]!;
  final String token = env["TOKEN"]!;

  Pyrite bot = Pyrite(token: token, publicKey: publicKey);
  bot.startServer();
}
