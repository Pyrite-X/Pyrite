import 'package:onyx/onyx.dart' show JsonData;

import '../structures/action.dart';
import '../structures/rule.dart';
import '../structures/server.dart';

import 'cache.dart' as redis;
import 'database.dart' as db;

const DEFAULT_SCAN_MAX_PER_WK = 3;

/// Fetches guild data from the cache and then the database.
Future<Server?> fetchGuildData(BigInt guildID, {bool withRules = false}) async {
  JsonData redisResponse = await redis.getServerConfig(guildID);
  Server? result;

  if (redisResponse.isNotEmpty) {
    result = Server.fromJson(data: redisResponse);
    if (withRules) {
      result.rules = await fetchGuildRules(guildID);
    }
  } else {
    // Get data from database because cache didn't have the entry.
    JsonData dbResponse = await db.fetchGuildData(serverID: guildID);
    if (dbResponse.isNotEmpty) {
      // Remove custom rules if not withRules.
      if (dbResponse["rules"] != null && !withRules) {
        List<dynamic> ruleList = dbResponse["rules"];
        ruleList.removeWhere((element) => element["type"] == 0);
        dbResponse["rules"] = ruleList;
      }
      // By default fetchGuildData includes all rules.
      result = Server.fromJson(data: dbResponse);

      // Cache server config and rules if withRules.
      redis.setServerConfig(result);
      if (withRules) {
        redis.cacheRules(guildID, result.rules);
      }
    } else {
      // No entry for this guild, add one. Don't cache it.
      var insertedData = await db.insertNewGuild(serverID: guildID);
      if (insertedData != null) {
        result = Server.fromJson(data: insertedData);
      }
      // At this point, there was likely an issue with contacting the database.
    }
  }

  return result;
}

/// Fetches custom rule data from the cache and then the database. Empty list
/// when there are no rules, or an issue occurred when getting the rules.
Future<List<Rule>> fetchGuildRules(BigInt guildID) async {
  List<Rule> ruleList = [];
  JsonData ruleMap = await redis.getRules(guildID);

  if (ruleMap.isNotEmpty) {
    ruleMap.forEach((key, value) => ruleList.add(Rule.fromJson(value)));
  } else {
    List<dynamic> data = await db.fetchGuildRules(serverID: guildID);
    if (data.isNotEmpty) {
      data.forEach((element) => ruleList.add(Rule.fromJson(element)));
    }
    // Cache the retrieved rules.
    redis.cacheRules(guildID, ruleList);
  }

  return ruleList;
}

/// Updates the saved guild config. On success it will clear any cached config.
Future<bool> updateGuildConfig(
    {required BigInt serverID,
    BigInt? logchannelID,
    bool? onJoinEvent,
    int? fuzzyMatchPercent,
    Action? phishingMatchAction,
    bool? phishingMatchEnabled,
    List<BigInt>? excludedRoles}) async {
  bool success = await db.updateGuildConfig(
      serverID: serverID,
      logchannelID: logchannelID,
      onJoinEvent: onJoinEvent,
      fuzzyMatchPercent: fuzzyMatchPercent,
      phishingMatchAction: phishingMatchAction,
      phishingMatchEnabled: phishingMatchEnabled,
      excludedRoles: excludedRoles);

  if (success) {
    redis.removeServerConfig(serverID);
  }

  return success;
}

/// Inserts a guild rule into the database. Clears all cached rules on success.
Future<bool> insertGuildRule({required BigInt serverID, required Rule rule}) async {
  bool success = await db.insertGuildRule(serverID: serverID, rule: rule);
  if (success) {
    redis.removeCachedRules(serverID);
  }

  return success;
}

/// Removes a [fieldName] from the database for a [serverID]. On success clears any cached server config.
Future<bool> removeGuildField({required BigInt serverID, required String fieldName}) async {
  var success = await db.removeGuildField(serverID: serverID, fieldName: fieldName);
  if (success) {
    redis.removeServerConfig(serverID);
  }

  return success;
}

/// Removes a rule from the database. On success clears all cached rules.
Future<bool> removeGuildRule({required BigInt serverID, required String ruleID}) async {
  bool success = await db.removeGuildRule(serverID: serverID, ruleID: ruleID);
  if (success) {
    redis.removeCachedRules(serverID);
  }

  return success;
}

Future<int> getScanCount(BigInt guildID) async {
  int? scanCount = await redis.getScanCount(guildID);
  if (scanCount == null) {
    await redis.initializeScanCount(guildID, DEFAULT_SCAN_MAX_PER_WK);
    scanCount = DEFAULT_SCAN_MAX_PER_WK;
  }
  return scanCount;
}

Future<bool> canRunScan(BigInt guildID) async {
  int scanCount = await getScanCount(guildID);
  return scanCount > 0;
}
