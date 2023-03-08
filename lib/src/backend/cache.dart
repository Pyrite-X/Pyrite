import 'package:onyx/onyx.dart' show JsonData;
import 'package:resp_client/resp_client.dart';
import 'package:resp_client/resp_commands.dart';
import 'package:resp_client/resp_server.dart' as resp_server;

import '../structures/rule.dart';
import '../structures/server.dart';

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

const CONFIG_KEY = "server_config";
const RULE_KEY = "server_rules";
const SCAN_KEY = "server_scans";
final AppCache _appCache = AppCache();

Future<JsonData> getServerConfig(BigInt serverID) async {
  var client = RespCommandsTier2(_appCache.cacheConnection);
  return await client.hgetall("$CONFIG_KEY\_$serverID");
}

Future<void> setServerConfig(Server server) async {
  var client = RespCommandsTier2(_appCache.cacheConnection);
  await client.multi();

  JsonData mappedData = server.toJson();
  mappedData.forEach((key, value) {
    client.hset("$CONFIG_KEY\_${server.serverID}", key, value);
  });

  await client.exec();
  client.pexpire("$CONFIG_KEY\_${server.serverID}", Duration(days: 7));
}

Future<bool> removeServerConfig(BigInt serverID) async {
  var client = RespCommandsTier2(_appCache.cacheConnection);
  return await client.del(["$CONFIG_KEY\_$serverID"]) == 1;
}

/// Returns the number of scans that can be performed in a week.
Future<int?> getScanCount(BigInt guildID) async {
  var client = RespCommandsTier2(_appCache.cacheConnection);
  String? keyValue = await client.hget(SCAN_KEY, guildID.toString());

  return (keyValue != null) ? int.tryParse(keyValue) : null;
}

/// Sets the scan count for [guildID] to [scanCount]. Sets the hash key TTL if new hash is made.
Future<void> initializeScanCount(BigInt guildID, int scanCount) async {
  var client = RespCommandsTier2(_appCache.cacheConnection);
  await client.hset(SCAN_KEY, guildID.toString(), scanCount);

  int ttl = await client.ttl(SCAN_KEY);

  /// New hash key created, need to set ttl.
  if (ttl == -1) {
    var currentTime = DateTime.now().toUtc();
    int daysUntilSunday =
        (currentTime.weekday == DateTime.sunday) ? 7 : DateTime.sunday - currentTime.weekday;

    /// Add in the day offset so it's now UTC midnight on sunday
    var sundayTime = currentTime.add(Duration(days: daysUntilSunday));

    /// Make a new time at midnight UTC since we need the original time for calculating the offset in seconds.
    var sundayDay = DateTime.utc(sundayTime.year, sundayTime.month, sundayTime.minute);
    Duration timeUntilSunday = sundayDay.difference(currentTime);

    await client.pexpire(SCAN_KEY, timeUntilSunday);
  }
}

/// Decreases the available scans given by 1. Returns the remaining count.
Future<int> decreaseScanCount(BigInt guildID) async {
  var client = RespCommandsTier2(_appCache.cacheConnection);
  var response = await client.tier1.tier0.execute(["HINCRBY", SCAN_KEY, guildID.toString(), -1]);
  return response.toInteger().payload;
}
