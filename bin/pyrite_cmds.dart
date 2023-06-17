import 'package:dotenv/dotenv.dart';
import 'package:lirx/lirx.dart';

void main() async {
  var env = DotEnv()..load(['bin/.env']);
  final String token = env["TOKEN"]!;
  final BigInt appId = BigInt.parse(env["APP_ID"]!);

  String? envUrl = env["DISCORD_URL"];
  if (envUrl != null) {
    envUrl = "http://${env["DISCORD_URL"]}/api/";
  }
  Lirx lirx = Lirx(botToken: token, applicationID: appId, discordURL: envUrl);
  await lirx.loadCommandFiles([
    'commands/about.toml',
    'commands/config.toml',
    'commands/help.toml',
    'commands/invite.toml',
    'commands/rules.toml',
    'commands/scan.toml',
    'commands/stats.toml'
  ]);

  // print(jsonEncode(lirx.commandList));
  var result = await lirx.bulkPublishCommands();
  result = result as List<dynamic>;
  print("${result.length} commands were published.");
  result.forEach((element) => print(element));
}
