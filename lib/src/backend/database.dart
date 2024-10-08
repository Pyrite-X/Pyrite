import 'package:logging/logging.dart';
import 'package:mongo_pool/mongo_pool.dart';
import 'package:onyx/onyx.dart' show JsonData;

import '../structures/action.dart';
import '../structures/rule.dart';

Logger _logger = Logger("Database");

class DatabaseClient {
  static final DatabaseClient _instance = DatabaseClient._init();
  DatabaseClient._init();

  late final MongoDbPoolService pool;
  late final String uri;

  factory DatabaseClient() {
    return _instance;
  }

  static Future<DatabaseClient> create(
      {bool initializing = false, String? uri, String databaseName = "pyrite"}) async {
    if (initializing) {
      _logger.info("Initializing connection to the database.");

      if (uri == null) {
        throw UnsupportedError("Cannot initialize a database client without a URI.");
      }

      _instance.pool = MongoDbPoolService(MongoPoolConfiguration(
          poolSize: 4,
          uriString: uri,
          maxLifetimeMilliseconds: 60 * 1000,
          leakDetectionThreshold: 10 * 1000));

      _logger.info("Opening connection to the database.");
      await _instance.pool.open();
    }

    _logger.info("Connected to the database(?)!");
    return _instance;
  }
}

final DatabaseClient _db = DatabaseClient();
final _defaultData = {
  "onJoinEnabled": true,
  "fuzzyMatchPercent": 100,
  "rules": [
    {"type": 1, "enabled": true, "action": ActionEnum.kick.value}
  ]
};

Future<dynamic> handleQuery(String collection, Future<dynamic> Function(DbCollection collection) func) async {
  Db connection = await _db.pool.acquire();

  if (!connection.isConnected) {
    await _db.pool.close();
    _logger.warning("Reconnecting to the database.");
    await _db.pool.open();

    connection = await _db.pool.acquire();
  }

  DbCollection col = connection.collection(collection);

  // Always release connection after execution.
  try {
    var result = await func(col);
    return result;
  } finally {
    _db.pool.release(connection);
  }
}

Future<JsonData?> insertNewGuild({required BigInt serverID}) async {
  WriteResult result = await handleQuery("guilds", (collection) async {
    return await collection.updateOne(
      {"_id": serverID.toString()},
      {"\$setOnInsert": _defaultData},
      upsert: true,
    );
  });

  return result.nUpserted == 1 ? {"_id": serverID, ..._defaultData} : null;
}

Future<JsonData> fetchGuildData({required BigInt serverID, List<String>? fields}) async {
  JsonData? data = await handleQuery("guilds", (collection) async {
    return await collection.findOne({"_id": serverID.toString()});
  });

  if (data == null) {
    return {};
  }

  if (fields != null && fields.isNotEmpty) {
    data.removeWhere((key, value) => !(key == "_id" || fields.contains(key)));
  }

  return data;
}

Future<bool> updateGuildConfig(
    {required BigInt serverID,
    BigInt? logchannelID,
    bool? onJoinEvent,
    int? fuzzyMatchPercent,
    Action? phishingMatchAction,
    bool? phishingMatchEnabled,
    List<BigInt>? excludedRoles}) async {
  JsonData queryMap = {"_id": serverID.toString()};
  JsonData updateMap = {};

  if (logchannelID != null) {
    updateMap["logchannelID"] = logchannelID.toString();
  }

  if (onJoinEvent != null) {
    updateMap["onJoinEnabled"] = onJoinEvent;
  }

  if (fuzzyMatchPercent != null) {
    if (fuzzyMatchPercent < 75) fuzzyMatchPercent = 75;
    if (fuzzyMatchPercent > 100) fuzzyMatchPercent = 100;
    updateMap["fuzzyMatchPercent"] = fuzzyMatchPercent;
  }

  if (phishingMatchAction != null) {
    queryMap["rules.type"] = 1;
    updateMap["rules.\$.action"] = phishingMatchAction.bitwiseValue;
  }

  if (phishingMatchEnabled != null) {
    queryMap["rules.type"] = 1;
    updateMap["rules.\$.enabled"] = phishingMatchEnabled;
  }

  if (excludedRoles != null) {
    List<String> convertedRoleList = [];
    excludedRoles.forEach((element) => convertedRoleList.add(element.toString()));
    updateMap["excludedRoles"] = convertedRoleList;
  }

  WriteResult result = await handleQuery("guilds", (collection) async {
    return await collection.updateOne(queryMap, {"\$set": updateMap});
  });

  return result.nModified == 1;
}

Future<bool> removeGuildField({required BigInt serverID, required String fieldName}) async {
  JsonData queryMap = {"_id": serverID.toString()};

  WriteResult result = await handleQuery("guilds", (collection) async {
    return await collection.updateOne(queryMap, {
      r"$unset": {fieldName: ""}
    });
  });

  return result.nModified == 1;
}

/// Query for the rules in a guild. Default [ruleType] is 0, which is custom rules.
/// [ruleType] of 1 returns the "phishing list" rule entry.
Future<List<dynamic>> fetchGuildRules({required BigInt serverID, int ruleType = 0}) async {
  /// Since I'll forget, projection chooses what is returned in the result. 1 for true, 0 for false.
  /// filter = selector, used to figure out what document to select.

  var query = await handleQuery("guilds", (collection) async {
    // return await collection.findOne({"_id": serverID.toString()});
    return await collection.modernFindOne(
      filter: {"_id": serverID.toString(), "rules.type": ruleType},
      projection: {"rules": 1, "_id": 0},
    );
  });

  // Rules of type 0 are custom rules. Filter out phishing rule entry.
  // Do the inverse if querying for phishing rule entry.
  int filterRule = (ruleType == 0) ? 1 : 0;

  if (query == null || query.isEmpty) {
    return [];
  } else {
    List<dynamic> payload = query["rules"];
    payload.removeWhere((e) => e["type"] == filterRule);
    return payload;
  }
}

Future<bool> insertGuildRule({required BigInt serverID, required Rule rule}) async {
  WriteResult result = await handleQuery("guilds", (collection) async {
    return await collection.updateOne({
      "_id": serverID.toString(),
      "rules": {
        "\$not": {
          "\$elemMatch": {
            "\$or": [
              {"ruleID": rule.ruleID},
              {"pattern": rule.pattern}
            ]
          }
        }
      }
    }, {
      "\$push": {
        'rules': {
          "type": 0,
          "ruleID": rule.ruleID,
          "authorID": rule.authorID.toString(),
          "pattern": rule.pattern,
          "action": rule.action.bitwiseValue,
          "isRegex": rule.regex
        }
      }
    });
  });

  return result.nModified == 1;
}

Future<bool> removeGuildRule({required BigInt serverID, required String ruleID}) async {
  WriteResult result = await handleQuery("guilds", (collection) async {
    return await collection.updateOne({
      "_id": serverID.toString()
    }, {
      "\$pull": {
        'rules': {"ruleID": ruleID}
      }
    });
  });

  return result.nModified == 1;
}

Future<bool> insertWhitelistEntry({required BigInt serverID, String? name, BigInt? roleID}) async {
  JsonData queryMap = {"_id": serverID.toString()};

  if (name == null && roleID == null) {
    throw UnsupportedError("Cannot insert whitelist entry if there is no name or roleID.");
  }

  bool nameResult = false;
  if (name != null) {
    WriteResult result = await handleQuery("guilds", (collection) async {
      return await collection.updateOne(queryMap, {
        r"$addToSet": {"whitelist.names": name}
      });
    });
    nameResult = result.nModified == 1;
  }

  bool roleResult = false;
  if (roleID != null) {
    WriteResult result = await handleQuery("guilds", (collection) async {
      return await collection.updateOne(queryMap, {
        r"$addToSet": {"whitelist.roles": roleID.toString()}
      });
    });
    roleResult = result.nModified == 1;
  }

  return (name != null && roleID != null) ? nameResult && roleResult : nameResult || roleResult;
}

Future<bool> removeWhitelistEntry({required BigInt serverID, String? name, BigInt? roleID}) async {
  JsonData queryMap = {"_id": serverID.toString()};

  if (name == null && roleID == null) {
    throw UnsupportedError("Cannot remove whitelist entry if there is no name or roleID.");
  }

  bool nameResult = false;
  if (name != null) {
    WriteResult result = await handleQuery("guilds", (collection) async {
      return await collection.updateOne(queryMap, {
        r"$pull": {"whitelist.names": name}
      });
    });
    nameResult = result.nModified == 1;
  }

  bool roleResult = false;
  if (roleID != null) {
    WriteResult result = await handleQuery("guilds", (collection) async {
      return await collection.updateOne(queryMap, {
        r"$pull": {"whitelist.roles": roleID}
      });
    });
    roleResult = result.nModified == 1;
  }

  return (name != null && roleID != null) ? nameResult && roleResult : nameResult || roleResult;
}

Future<bool> insertManyWhitelistEntries(
    {required BigInt serverID, List<String>? names, List<BigInt>? roles}) async {
  JsonData queryMap = {"_id": serverID.toString()};

  if (names == null && roles == null) {
    throw UnsupportedError("Cannot insert whitelist entries if there are no entries to add.");
  }

  if ((names != null && names.isEmpty) || (roles != null && roles.isEmpty)) {
    throw UnsupportedError("Cannot insert whitelist entries if there are no entries to add in the list.");
  }

  bool nameResult = false;
  if (names != null) {
    WriteResult result = await handleQuery("guilds", (collection) async {
      return await collection.updateOne(queryMap, {
        r"$addToSet": {
          "whitelist.names": {r"$each": names}
        }
      });
    });
    nameResult = result.nModified == 1;
  }

  bool roleResult = false;
  if (roles != null) {
    WriteResult result = await handleQuery("guilds", (collection) async {
      return await collection.updateOne(queryMap, {
        r"$addToSet": {
          "whitelist.roles": {
            r"$each": [for (BigInt role in roles) role.toString()]
          }
        }
      });
    });
    roleResult = result.nModified == 1;
  }

  return (names != null && roles != null) ? nameResult && roleResult : nameResult || roleResult;
}

Future<bool> removeManyWhitelistEntries({
  required BigInt serverID,
  List<String>? names,
  List<BigInt>? roles,
}) async {
  JsonData queryMap = {"_id": serverID.toString()};

  if (names == null && roles == null) {
    throw UnsupportedError("Cannot remove from the whitelist if there is nothing to remove.");
  }

  if ((names != null && names.isEmpty) || (roles != null && roles.isEmpty)) {
    throw UnsupportedError(
        "Cannot remove from the whitelist if there is nothing to remove in the given list.");
  }

  bool nameResult = false;
  if (names != null) {
    WriteResult result = await handleQuery("guilds", (collection) async {
      return await collection.updateOne(queryMap, {
        r"$pull": {
          "whitelist.names": {"\$in": names}
        }
      });
    });
    nameResult = result.nModified == 1;
  }

  bool roleResult = false;
  if (roles != null) {
    WriteResult result = await handleQuery("guilds", (collection) async {
      return await collection.updateOne(queryMap, {
        r"$pull": {
          "whitelist.roles": {
            "\$in": [for (BigInt roleID in roles) roleID.toString()]
          }
        }
      });
    });
    roleResult = result.nModified == 1;
  }

  return (names != null && roles != null) ? nameResult && roleResult : nameResult || roleResult;
}
