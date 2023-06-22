import 'dart:convert';

import 'package:onyx/onyx.dart' show JsonData;

import '../structures/action.dart';
import '../structures/rule.dart';
import '../structures/server.dart';

import 'cache.dart' as redis;
import 'database.dart' as db;

const DEFAULT_SCAN_MAX_PER_WK = 3;
const DEFAULT_RULE_LIMIT = 10;
const DEFAULT_REGEX_RULE_LIMIT = 2;

/// Fetches guild data from the cache and then the database.
Future<Server?> fetchGuildData(BigInt guildID, {bool withRules = false, bool withWhitelist = true}) async {
  JsonData redisResponse = await redis.getServerConfig(guildID);
  Server? result;

  bool queriedDatabase = false;

  if (redisResponse.isNotEmpty) {
    result = Server.fromJson(data: redisResponse);
  } else {
    // Get data from database because cache didn't have the entry.
    // Contains all data, so just populate as necessary and cache.
    JsonData dbResponse = await db.fetchGuildData(serverID: guildID);
    queriedDatabase = true;
    if (dbResponse.isNotEmpty) {
      // Remove custom rules if not withRules.
      // Phishing list settings are a rule of type 1, so we can't just drop the rule list entirely.
      // TODO: Move phishing list out of the rule configuration and into its own sub-dict.
      if (dbResponse["rules"] != null && !withRules) {
        List<dynamic> ruleList = dbResponse["rules"];
        ruleList.removeWhere((element) => element["type"] == 0);
        dbResponse["rules"] = ruleList;
      }

      if (dbResponse["whitelist"] != null && !withWhitelist) {
        dbResponse["whitelist"] = null;
      }
      result = Server.fromJson(data: dbResponse);

      // Cache server config and rules if withRules.
      redis.setServerConfig(result);
      if (withRules && result.rules.isNotEmpty) {
        redis.cacheRules(guildID, result.rules);
      }
      if (withWhitelist && (result.excludedRoles.isNotEmpty || result.excludedNames.isNotEmpty)) {
        redis.addToWhitelist(guildID, roles: result.excludedRoles, names: result.excludedNames);
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

  if (result != null) {
    // If the guild data was cached, check for rules and whitelist and set.
    if (!queriedDatabase && withRules && result.rules.isEmpty) {
      List<Rule> response = await fetchGuildRules(guildID);
      result.rules = response;
    }

    if (!queriedDatabase && withWhitelist && (result.excludedNames.isEmpty || result.excludedRoles.isEmpty)) {
      JsonData response = await fetchGuildWhitelist(guildID);
      result.excludedNames = response["names"];
      result.excludedRoles = response["roles"];
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
    ruleMap.forEach((key, value) => ruleList.add(Rule.fromJson(jsonDecode(value))));
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

Future<JsonData> fetchGuildWhitelist(BigInt guildID) async {
  JsonData output = {"names": [], "roles": []};

  JsonData whitelist = await redis.getWhitelist(guildID, roles: true, names: true);
  output["roles"] = whitelist["roles"];
  output["names"] = whitelist["names"];

  if ((output["roles"] as List).isEmpty || (output["names"] as List).isEmpty) {
    JsonData dbData = await db.fetchGuildData(serverID: guildID, fields: ["whitelist"]);

    if ((dbData["roles"] as List).isNotEmpty) {
      output["roles"] = [for (String role in dbData["roles"]) BigInt.parse(role)];
    }
    if ((dbData["names"] as List).isNotEmpty) {
      output["names"] = dbData["names"];
    }

    redis.addToWhitelist(guildID, roles: output["roles"], names: output["names"]);
  }

  return output;
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

Future<int> getGuildRuleCount(BigInt guildID) async {
  return (await fetchGuildRules(guildID)).length;
}

Future<int> getGuildRegexRuleCount(BigInt guildID) async {
  List<Rule> rList = await fetchGuildRules(guildID);
  rList.removeWhere((element) => !element.regex);
  return rList.length;
}

Future<JsonData> canAddRule(BigInt guildID, {Rule? rule}) async {
  int ruleCount = await getGuildRuleCount(guildID);
  JsonData response = {"flag": true, "reason": ""};

  if (ruleCount >= DEFAULT_RULE_LIMIT) {
    response["flag"] = false;
    response["reason"] = "You are at the limit of $DEFAULT_RULE_LIMIT rules.";
  } else if (rule != null) {
    if (rule.regex) {
      int regexRuleCount = await getGuildRegexRuleCount(guildID);
      if (regexRuleCount >= DEFAULT_REGEX_RULE_LIMIT) {
        response["flag"] = false;
        response["reason"] = "You are at the limit of $DEFAULT_REGEX_RULE_LIMIT regex rules.";
      }
    }
  }

  return response;
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

Future<bool> addToWhitelist(BigInt guildID, {List<BigInt>? roles, List<String>? names}) async {
  redis.addToWhitelist(guildID, roles: roles, names: names);
  return await db.insertManyWhitelistEntries(serverID: guildID, roles: roles, names: names);
}

Future<bool> removeFromWhitelist(BigInt guildID, {List<BigInt>? roles, List<String>? names}) async {
  redis.removeFromWhitelist(guildID, roles: roles, names: names);
  return await db.removeManyWhitelistEntries(serverID: guildID, roles: roles, names: names);
}

Future<bool> clearWhitelist(BigInt guildID, {bool roles = false, bool names = false}) async {
  bool cacheDump = await redis.clearWhitelist(guildID, roles: roles, names: names);

  bool roleDump = false;
  bool nameDump = false;

  if (roles) {
    roleDump = await db.removeGuildField(serverID: guildID, fieldName: "whitelist.roles");
  }

  if (names) {
    nameDump = await db.removeGuildField(serverID: guildID, fieldName: "whitelist.names");
  }

  nameDump = (names == nameDump);
  roleDump = (roles == roleDump);
  return cacheDump && nameDump && roleDump;
}
