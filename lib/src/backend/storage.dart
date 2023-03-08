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
    List<Rule> ruleList = [];
    if (withRules) {
      // Try getting rules from cache.
      JsonData cachedRules = await redis.getRules(guildID);
      if (cachedRules.isEmpty) {
        // Try getting rules from database.
        var dbRules = await db.fetchGuildRules(serverID: guildID);
        if (dbRules.isNotEmpty) {
          dbRules.forEach((element) => ruleList.add(Rule.fromJson(element)));
          // Cache the rules gotten.
          redis.cacheRules(guildID, ruleList);
        }
        // No rules were found above.
      } else {
        cachedRules.forEach((key, value) => ruleList.add(Rule.fromJson(value)));
      }
      result.rules = ruleList;
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
    } else {
      // No entry for this guild, add one.
      var insertedData = await db.insertNewGuild(serverID: guildID);
      if (insertedData != null) {
        result = Server.fromJson(data: insertedData);
      }
      // At this point, there was likely an issue with contacting the database.
    }
  }

  return result;
}
