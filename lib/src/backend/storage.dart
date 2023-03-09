import 'package:onyx/onyx.dart' show JsonData;

import '../structures/rule.dart';
import '../structures/server.dart';

import 'cache.dart' as redis;
import 'database.dart' as db;

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
