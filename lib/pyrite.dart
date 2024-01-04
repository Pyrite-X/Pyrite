import 'dart:async';
import 'dart:io';

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
// ignore: unused_import
import 'src/modules/interactions/redeem.dart' as redeem;
import 'src/modules/interactions/rules.dart' as rules;
import 'src/modules/interactions/scan.dart' as scan;
import 'src/modules/interactions/stats.dart' as stats;
// ignore: unused_import
import 'src/modules/interactions/transfer.dart' as transfer;

import 'src/modules/interactions/buttons/log_button.dart' as log_button;
import 'src/modules/interactions/buttons/whitelist_buttons.dart' as whitelist_buttons;

import 'src/modules/interactions/select_menus/whitelist_roles.dart' as whitelist_sel;

// ignore: library_prefixes
import 'src/utilities/ignore_exceptions.dart' as IE;

late final int _startTime;

class Pyrite {
  final String token;
  final String publicKey;
  final BigInt appID;
  late final Onyx onyx;
  late final NyxxGateway gateway;

  // ignore: unused_field
  final Logger _logger = Logger("Pyrite");

  Pyrite({required this.token, required this.publicKey, required this.appID});

  // ignore: non_constant_identifier_names
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

  Future<void> startGateway({bool ignoreExceptions = false, bool handleSignals = false}) async {
    gateway = await Nyxx.connectGateway(token, GatewayIntents.guildMembers | GatewayIntents.guilds);

    gateway.onGuildMemberAdd.listen((event) => on_join_event.on_join_event(event));
    gateway.onGuildCreate.listen((event) => on_guild_create.on_guild_create(event));

    gateway.onReady.listen((event) {
      gateway.updatePresence(PresenceBuilder(
          status: CurrentUserStatus.online,
          activities: [ActivityBuilder(name: "for suspicious users...", type: ActivityType.watching)],
          isAfk: false));

      gateway.gateway.messages.listen((event) {
        if (event is! EventReceived) return;

        final realEvent = event.event;
        if (realEvent is! RawDispatchEvent) return;

        if (realEvent.name == "GUILD_MEMBER_UPDATE") {
          on_member_update.on_member_update(realEvent.payload);
        }
      });
    });

    /// Load the list on init, then update every 30 minutes.
    unawaited(loadPhishingList());
    Timer.periodic(Duration(minutes: 30), ((timer) => loadPhishingList()));

    if (ignoreExceptions) IE.ignoreExceptions();
  }

  Future<void> startServer(
      {bool ignoreExceptions = false,
      bool handleSignals = false,
      int serverPort = 8080,
      SecurityContext? securityContext}) async {
    _startTime = (DateTime.now().toUtc().millisecondsSinceEpoch / 1000).round();

    onyx = Onyx();
    onyx.registerAppCommandHandler("about", about.aboutCmd);
    onyx.registerAppCommandHandler("config", config.configCmd);
    onyx.registerAppCommandHandler("help", help.helpCmd);
    onyx.registerAppCommandHandler("invite", invite.inviteCmd);
    // onyx.registerAppCommandHandler("redeem", redeem.redeemCmd);
    onyx.registerAppCommandHandler("rules", rules.rulesCmd);
    onyx.registerAppCommandHandler("scan", scan.scanCmd);
    onyx.registerAppCommandHandler("stats", ((p0) => stats.statsCommand(p0, _startTime)));
    // onyx.registerAppCommandHandler("transfer", transfer.transferCmd);

    onyx.registerGenericComponentHandler("log_button", log_button.logButtonHandler);
    onyx.registerGenericComponentHandler("whitelist:clear", whitelist_buttons.clearButtonHandler);

    onyx.registerGenericComponentHandler("whitelist:sel", whitelist_sel.roleMenuHandler);

    Alfred alfred = Alfred();
    alfred.logWriter = _interceptAlfredLogs;

    WebServer server = WebServer(alfred, publicKey);
    await server.startServer(
        dispatchFunc: ((p0) async {
          var currentMetadata = p0.metadata;
          Map<String, dynamic> newMetadata = {"request": currentMetadata, "pyrite": this};

          p0.setMetadata(newMetadata);
          await onyx.dispatchInteraction(p0);
        }),
        port: serverPort,
        securityContext: securityContext);

    /// Load the list on init, then update every 30 minutes.
    unawaited(loadPhishingList());
    Timer.periodic(Duration(minutes: 30), ((timer) => loadPhishingList()));

    /// Have the queue check status and/or start a server scan every minute.
    Timer.periodic(Duration(minutes: 1), ((timer) => scan.queueHandler()));

    if (ignoreExceptions) IE.ignoreExceptions();
  }
}
