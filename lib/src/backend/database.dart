import 'package:logging/logging.dart';
// import 'package:mongo_pool/mongo_pool.dart';
import 'package:mongo_go/mongo_go.dart';
import 'package:mongo_go/src/update_options.dart';
import 'package:onyx/onyx.dart' show JsonData;

import '../structures/action.dart';
import '../structures/rule.dart';

Logger _logger = Logger("Database");

class DatabaseClient {
  static final DatabaseClient _instance = DatabaseClient._init();
  DatabaseClient._init();

  late final Connection connection;
  late final Database database;
  late final String uri;

  factory DatabaseClient() {
    return _instance;
  }

  static Future<DatabaseClient> create(
      {bool initializing = false, String? uri, String databaseName = "pyrite"}) async {
    if (initializing) {
      _logger.info("Initializing connection to the database.");
      if (uri != null) {
        _instance.connection = await Connection.connectWithString(uri);
        _instance.uri = uri;
      } else {
        throw UnsupportedError("Cannot initialize a database client without a URI.");
      }

      _logger.info("Opening connection to the database.");
      _instance.database = await _instance.connection.database(databaseName);
    }

    _logger.info("Connected to the database!");
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

Future<dynamic> handleQuery(String collection, Future<dynamic> func(Collection collection)) async {
  Collection col = await _db.database.collection(collection);
  var result = await func(col);

  return result;
}

Future<JsonData?> insertNewGuild({required BigInt serverID}) async {
  UpdateResult result = await handleQuery("guilds", (collection) async {
    return await collection.updateOne({"_id": serverID.toString()}, {"\$setOnInsert": _defaultData},
        options: UpdateOptions(isUpsert: true));
  });

  return result.upsertedCount == 1 ? {"_id": serverID, ..._defaultData} : null;
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

  UpdateResult result = await handleQuery("guilds", (collection) async {
    return await collection.updateOne(queryMap, {"\$set": updateMap});
  });

  return result.modifiedCount == 1;
}

Future<bool> removeGuildField({required BigInt serverID, required String fieldName}) async {
  JsonData queryMap = {"_id": serverID.toString()};

  UpdateResult result = await handleQuery("guilds", (collection) async {
    return await collection.updateOne(queryMap, {
      r"$unset": {fieldName: ""}
    });
  });

  return result.modifiedCount == 1;
}

/// Query for the rules in a guild. Default [ruleType] is 0, which is custom rules.
/// [ruleType] of 1 returns the "phishing list" rule entry.
Future<List<dynamic>> fetchGuildRules({required BigInt serverID, int ruleType = 0}) async {
  /// Since I'll forget, projection chooses what is returned in the result. 1 for true, 0 for false.
  /// filter is filter, basically is used to figure out what document to select.
  ///
  /// TODO: complain to mongo_go devs about a lack of options on findOne... can't provide projection.
  var query = await handleQuery("guilds", (collection) async {
    return await collection.findOne({"_id": serverID.toString()});
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
  UpdateResult result = await handleQuery("guilds", (collection) async {
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

  return result.modifiedCount == 1;
}

Future<bool> removeGuildRule({required BigInt serverID, required String ruleID}) async {
  UpdateResult result = await handleQuery("guilds", (collection) async {
    return await collection.updateOne({
      "_id": serverID.toString()
    }, {
      "\$pull": {
        'rules': {"ruleID": ruleID}
      }
    });
  });

  return result.modifiedCount == 1;
}
