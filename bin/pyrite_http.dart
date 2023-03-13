import 'package:dotenv/dotenv.dart';
import 'package:logging/logging.dart';

import 'package:pyrite/pyrite.dart';
import 'package:pyrite/src/discord_http.dart';
import 'package:pyrite/src/backend/database.dart';
import 'package:pyrite/src/backend/cache.dart';

void main(List<String> arguments) async {
  var env = DotEnv(includePlatformEnvironment: true);
  try {
    env.load(['bin/.env']);
  } on UnsupportedError {
    env.load();
  }

  final BigInt appID = BigInt.parse(env["APP_ID"]!);
  final String publicKey = env["PUB_KEY"]!;
  final String token = env["TOKEN"]!;

  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    Pyrite.handleLogOutput(record);
  });

  /// Initialize DiscordHTTP with custom settings
  int? proxyPort;
  if (env["PORT"] != null) {
    proxyPort = int.tryParse(env["PORT"]!);
  }

  DiscordHTTP(
      authToken: token,
      applicationID: appID,
      discordURL: env["DISCORD_URL"],
      scheme: env["DISCORD_SCHEME"],
      port: proxyPort);

  /// Start the database connection.
  await DatabaseClient.create(initializing: true, uri: env["MONGO_URI"]);

  /// Start the connection to Redis.
  await AppCache.init(host: env["REDIS_HOST"]!, port: int.parse(env["REDIS_PORT"]!), auth: env["REDIS_PASS"]);

  /// Start bot features.
  Pyrite bot = Pyrite(token: token, publicKey: publicKey, appID: appID);
  bot.startServer(ignoreExceptions: true, serverPort: 8008);
}
