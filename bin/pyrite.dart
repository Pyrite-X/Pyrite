import 'package:dotenv/dotenv.dart';
import 'package:pyrite/pyrite.dart';
import 'package:pyrite/src/discord_http.dart';

void main(List<String> arguments) {
  var env = DotEnv()..load(['bin/.env']);
  final BigInt appID = BigInt.parse(env["APP_ID"]!);
  final String publicKey = env["PUB_KEY"]!;
  final String token = env["TOKEN"]!;

  DiscordHTTP restClient =
      DiscordHTTP(authToken: publicKey, applicationID: appID, discordURL: "192.168.254.108");

  Pyrite bot = Pyrite(token: token, publicKey: publicKey, appID: appID, restClient: restClient);
  bot.startServer();
  // bot.startGateway();
}
