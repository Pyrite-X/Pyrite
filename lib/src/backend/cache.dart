import 'package:resp_client/resp_client.dart';
import 'package:resp_client/resp_commands.dart';
import 'package:resp_client/resp_server.dart' as resp_server;

/// Base class for holding the cache object.
class AppCache {
  static final AppCache _instance = AppCache._init();
  AppCache._init();

  late final RespClient cacheConnection;

  factory AppCache() {
    return _instance;
  }

  static Future<AppCache> init({String host = "localhost", int port = 6379, String? auth}) async {
    var serverConnection = await resp_server.connectSocket(host, port: port);
    RespClient client = RespClient(serverConnection);
    _instance.cacheConnection = client;

    if (auth != null) {
      RespCommandsTier2(client).auth(auth);
    }

    return _instance;
  }
}

/// Contains all methods relevant to caching custom rules created by a server.
class RuleCache {
  static const BASE_STRING = "server_rules";
  AppCache appCache = AppCache();
}

/// Contains all methods relevant to tracking the scan state for a server.
///
/// This includes how many remaining scans the server has for a week (3 - free, 5 - essential tier, or 7 - enhanced tier).
/// Entries expire on UTC Sunday at midnight. When an entry is missing, assume that the maximum is available for their tier.
class ScanCache {
  static const BASE_STRING = "server_scans";
  AppCache appCache = AppCache();
}

/// Contains all methods relevant towards caching server configuration data.
///
/// This includes essentially all information stored about the server in the database - so the join action,
/// log channel, if the bot should act when people join, and so on.
class ServerCache {
  static const BASE_STRING = "server_config";
  AppCache appCache = AppCache();
}
