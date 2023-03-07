import 'package:dotenv/dotenv.dart';
import 'package:pyrite/pyrite.dart';
import 'package:pyrite/src/backend/database.dart';
import 'package:pyrite/src/discord_http.dart';

void main(List<String> arguments) async {
  var env = DotEnv()..load(['bin/.env']);
  final BigInt appID = BigInt.parse(env["APP_ID"]!);
  final String publicKey = env["PUB_KEY"]!;
  final String token = env["TOKEN"]!;

  /// Initialize DiscordHTTP with custom settings
  DiscordHTTP(authToken: token, applicationID: appID, discordURL: "192.168.254.108", scheme: "http");

  /// Start the database connection.
  /// Insecure connection is used for development.
  await DatabaseClient.create(initializing: true, uri: env["MONGO_URI"]);

  /// Start bot features.
  Pyrite bot = Pyrite(token: token, publicKey: publicKey, appID: appID);
  bot.startServer();
  bot.startGateway();
}
