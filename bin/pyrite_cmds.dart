import 'package:dotenv/dotenv.dart';
import 'package:lirx/lirx.dart';

void main() async {
  var env = DotEnv()..load(['bin/.env']);
  final String token = env["TOKEN"]!;
  final BigInt appId = BigInt.parse(env["APP_ID"]!);

  Lirx lirx = Lirx(botToken: token, applicationID: appId);
  await lirx.loadCommandFiles([
    'commands/about.toml',
    'commands/config.toml',
    'commands/help.toml',
    'commands/redeem.toml',
    'commands/rules.toml',
    'commands/scan.toml',
    'commands/transfer.toml'
  ]);

  // print(jsonEncode(lirx.commandList));
  print(await lirx.bulkPublishCommands());
}
