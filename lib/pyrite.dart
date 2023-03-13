import 'dart:async';

import 'package:alfred/alfred.dart';
import 'package:ansicolor/ansicolor.dart';
import 'package:logging/logging.dart';
import 'package:nyxx/nyxx.dart';
import 'package:onyx/onyx.dart';

import 'src/backend/webserver.dart';
import 'src/backend/checks/check_phish_list.dart';

import 'src/modules/gateway/on_join_event.dart' as on_join_event;
import 'src/modules/gateway/on_guild_create.dart' as on_guild_create;
import 'src/modules/gateway/on_member_update.dart' as on_member_update;

import 'src/modules/interactions/about.dart' as about;
import 'src/modules/interactions/config.dart' as config;
import 'src/modules/interactions/help.dart' as help;
import 'src/modules/interactions/invite.dart' as invite;
import 'src/modules/interactions/redeem.dart' as redeem;
import 'src/modules/interactions/rules.dart' as rules;
import 'src/modules/interactions/scan.dart' as scan;
import 'src/modules/interactions/transfer.dart' as transfer;

import 'src/utilities/ignore_exceptions.dart' as IE;

class Pyrite {
  final String token;
  final String publicKey;
  final BigInt appID;
  late final Onyx onyx;
  late final INyxxWebsocket gateway;

  Pyrite({required this.token, required this.publicKey, required this.appID});

  static final ELEVATED_INFO = Level("INFO", 825);

  static String? _styleLogOutput(LogRecord record) {
    /// The mongo package prints to these on the info level and it leaks some private data
    /// (plus idc about those prints on the log level, but it doesn't have a way to override just that log level)
    if (record.loggerName == "dns_llokup" || record.loggerName == "HttpUtils") {
      return null;
    }
    StringBuffer output = StringBuffer();

    output.write("[${record.time.toIso8601String()}] ");

    AnsiPen pen = AnsiPen();
    if (record.level.value > ELEVATED_INFO.value && record.level.value <= Level.WARNING.value) {
      pen.yellow(bold: true);
    } else if (record.level.value > Level.WARNING.value) {
      pen.red(bold: true);
    } else {
      pen.white(bold: true);
    }
    output.write(pen("[${record.level.name}]"));

    output.write(" [${record.loggerName}]: ${record.message}");
    return output.toString();
  }

  static void _interceptAlfredLogs(dynamic Function() messageFn, LogType type) {
    /// This is dumb honestly, but Alfred uses its own function to output to that you have
    /// to override, and they also don't use the logging package.
    Level level;
    if (type == LogType.debug) {
      level = Level.FINE;
    } else if (type == LogType.warn) {
      level = Level.WARNING;
    } else if (type == LogType.error) {
      level = Level.SEVERE;
    } else {
      level = ELEVATED_INFO;
    }

    LogRecord record = LogRecord(level, messageFn().toString(), "Alfred");
    handleLogOutput(record);
  }

  static void handleLogOutput(LogRecord record) {
    if (record.level.value < Logger.root.level.value) return;
    String? log = _styleLogOutput(record);
    if (log == null) {
      return;
    }
    print(_styleLogOutput(record));
  }

  void startGateway({bool ignoreExceptions = false, bool handleSignals = false}) async {
    gateway = NyxxFactory.createNyxxWebsocket(token, GatewayIntents.guildMembers | GatewayIntents.guilds);

    gateway.eventsWs.onGuildMemberAdd.listen((event) => on_join_event.on_join_event(event));
    gateway.eventsWs.onGuildMemberUpdate.listen((event) => on_member_update.om_member_update(event));
    gateway.eventsWs.onGuildCreate.listen((event) => on_guild_create.on_guild_create(event));

    gateway.eventsWs.onReady.listen((event) {
      gateway.setPresence(PresenceBuilder.of(
          status: UserStatus.idle,
          activity: ActivityBuilder("for suspicious users...", ActivityType.watching)));
    });

    if (ignoreExceptions) IE.ignoreExceptions();

    await gateway.connect();
  }

  void startServer({bool ignoreExceptions = false, bool handleSignals = false, int serverPort = 8080}) async {
    onyx = Onyx();
    onyx.registerAppCommandHandler("about", about.aboutCmd);
    onyx.registerAppCommandHandler("config", config.configCmd);
    onyx.registerAppCommandHandler("help", help.helpCmd);
    onyx.registerAppCommandHandler("invite", invite.helpCmd);
    // onyx.registerAppCommandHandler("redeem", redeem.redeemCmd);
    onyx.registerAppCommandHandler("rules", rules.rulesCmd);
    onyx.registerAppCommandHandler("scan", scan.scanCmd);
    // onyx.registerAppCommandHandler("transfer", transfer.transferCmd);

    Alfred alfred = Alfred();
    alfred.logWriter = _interceptAlfredLogs;

    WebServer server = WebServer(alfred, publicKey);
    server.startServer(
        dispatchFunc: ((p0) {
          var currentMetadata = p0.metadata;
          Map<String, dynamic> newMetadata = {"request": currentMetadata, "pyrite": this};

          p0.setMetadata(newMetadata);
          onyx.dispatchInteraction(p0);
        }),
        port: serverPort);

    /// Load the list on init, then update every 30 minutes.
    loadPhishingList();
    Timer.periodic(Duration(minutes: 30), ((timer) => loadPhishingList()));

    /// Have the queue check status and/or start a server scan every minute.
    Timer.periodic(Duration(minutes: 1), ((timer) => scan.queueHandler()));

    if (ignoreExceptions) IE.ignoreExceptions();
  }
}
