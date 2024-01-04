import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:onyx/onyx.dart' show JsonData;
import 'package:resp_client/resp_client.dart';
import 'package:resp_client/resp_commands.dart';
import 'package:resp_client/resp_server.dart' as resp_server;

import '../structures/rule.dart';
import '../structures/server.dart';

Logger _logger = Logger("Redis");

/// Base class for holding the cache object.
class AppCache {
  static final AppCache _instance = AppCache._init();
  AppCache._init();

  late final RespClient cacheConnection;

  factory AppCache() {
    return _instance;
  }

  static Future<AppCache> init({String host = "localhost", int port = 6379, String? auth}) async {
    _logger.info("Connecting to Redis at host $host:$port.");
    var serverConnection = await resp_server.connectSocket(host, port: port);
    RespClient client = RespClient(serverConnection);
    _instance.cacheConnection = client;

    if (auth != null) {
      _logger.info("Authenticating with Redis.");
      await RespCommandsTier2(client).auth(auth);
    }

    _logger.info("Connected to the Redis cache!");
    return _instance;
  }
}

const CONFIG_KEY = "server_config";
const RULE_KEY = "server_rules";
const SCAN_KEY = "server_scans";
const WHITELIST_KEY = "server_whitelist";
const BASE_TIMEOUT = Duration(days: 3);
final AppCache _appCache = AppCache();

Future<JsonData> getServerConfig(BigInt serverID) async {
  var client = RespCommandsTier2(_appCache.cacheConnection);
  return await client.hgetall("$CONFIG_KEY\_$serverID");
}

Future<void> setServerConfig(Server server) async {
  var client = RespCommandsTier2(_appCache.cacheConnection);

  JsonData mappedData = server.toJson();
  List<String> commands = [];
  mappedData.forEach((key, value) {
    commands.add(key.toString());
    commands.add(value.toString());
  });

  await client.tier1.tier0.execute(["HSET", "$CONFIG_KEY\_${server.serverID}", ...commands]);
  await client.pexpire("$CONFIG_KEY\_${server.serverID}", BASE_TIMEOUT);
}

Future<bool> removeServerConfig(BigInt serverID) async {
  var client = RespCommandsTier2(_appCache.cacheConnection);
  return await client.del(["$CONFIG_KEY\_$serverID"]) == 1;
}

Future<void> cacheRules(BigInt serverID, List<Rule> ruleList) async {
  var client = RespCommandsTier2(_appCache.cacheConnection);
  List<String> commands = [];

  ruleList.forEach((element) {
    JsonData ruleJson = element.toJson();
    String ruleID = ruleJson["ruleID"];

    commands.add(ruleID);
    commands.add(jsonEncode(ruleJson));
  });

  await client.tier1.tier0.execute(["HSET", "$RULE_KEY\_$serverID", ...commands]);
  await client.pexpire("$RULE_KEY\_$serverID", BASE_TIMEOUT);
}

Future<JsonData> getRules(BigInt serverID, {List<String>? ruleIDs}) async {
  var client = RespCommandsTier2(_appCache.cacheConnection);
  JsonData result = await client.hgetall("$RULE_KEY\_$serverID");

  if (ruleIDs != null) {
    result.removeWhere((key, value) => !ruleIDs.contains(key));
  }

  return result;
}

Future<bool> removeCachedRules(BigInt serverID) async {
  var client = RespCommandsTier2(_appCache.cacheConnection);
  return await client.del(["$RULE_KEY\_$serverID"]) == 1;
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
    var sundayDay = DateTime.utc(sundayTime.year, sundayTime.month, sundayTime.day);
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

Future<void> addToWhitelist(BigInt serverID, {List<BigInt>? roles, List<String>? names}) async {
  if (roles == null && names == null) {
    throw UnsupportedError("Can't add to nothing!");
  }

  var client = RespCommandsTier2(_appCache.cacheConnection);

  if (roles != null) {
    await client.tier1.tier0.execute(["SADD", "$WHITELIST_KEY\_$serverID\_roles", ...roles]);
    await client.pexpire("$WHITELIST_KEY\_$serverID\_roles", BASE_TIMEOUT);
  }

  if (names != null) {
    await client.tier1.tier0.execute(["SADD", "$WHITELIST_KEY\_$serverID\_names", ...names]);
    await client.pexpire("$WHITELIST_KEY\_$serverID\_names", BASE_TIMEOUT);
  }
}

Future<void> removeFromWhitelist(BigInt serverID, {List<BigInt>? roles, List<String>? names}) async {
  if (roles == null && names == null) {
    throw UnsupportedError("Can't remove from nothing!");
  }

  var client = RespCommandsTier2(_appCache.cacheConnection);

  if (roles != null) {
    await client.tier1.tier0.execute(["SREM", "$WHITELIST_KEY\_$serverID\_roles", ...roles]);
  }

  if (names != null) {
    await client.tier1.tier0.execute(["SREM", "$WHITELIST_KEY\_$serverID\_names", ...names]);
  }
}

Future<bool> clearWhitelist(BigInt serverID, {bool roles = false, bool names = false}) async {
  if (!roles && !names) {
    throw UnsupportedError("To clear, one must either clear the roles, the names, or both.");
  }

  var client = RespCommandsTier2(_appCache.cacheConnection);
  bool roleSuccess = false;
  bool nameSuccess = false;

  if (roles) {
    roleSuccess = await client.del(["$WHITELIST_KEY\_$serverID\_roles"]) == 1;
  }

  if (names) {
    nameSuccess = await client.del(["$WHITELIST_KEY\_$serverID\_names"]) == 1;
  }

  return (roles && names) ? nameSuccess && roleSuccess : nameSuccess || roleSuccess;
}

Future<JsonData> getWhitelist(BigInt serverID, {bool roles = false, bool names = false}) async {
  if (!roles && !names) {
    throw UnsupportedError("Can't get nothing from the whitelist! No point in that.");
  }

  JsonData output = {"roles": [], "names": []};

  var client = RespCommandsTier2(_appCache.cacheConnection);

  if (roles) {
    var roleRequest = await client.tier1.tier0.execute(["SMEMBERS", "$WHITELIST_KEY\_$serverID\_roles"]);
    if (roleRequest.isArray) {
      var arr = roleRequest.toArray().payload;

      if (arr != null) {
        output["roles"] = [
          for (var item in arr)
            if (item.toBulkString().payload != null) BigInt.parse(item.toBulkString().payload!)
        ];
      }
    }
  }

  if (names) {
    var nameRequest = await client.tier1.tier0.execute(["SMEMBERS", "$WHITELIST_KEY\_$serverID\_names"]);
    if (nameRequest.isArray) {
      var arr = nameRequest.toArray().payload;

      if (arr != null) {
        output["names"] = [
          for (var item in arr)
            if (item.toBulkString().payload != null) item.toBulkString().payload!
        ];
      }
    }
  }

  return output;
}
