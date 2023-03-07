import 'package:mongo_dart/mongo_dart.dart';
import 'package:onyx/onyx.dart' show JsonData;

import '../structures/action.dart';
import '../structures/rule.dart';

class DatabaseClient {
  static final DatabaseClient _instance = DatabaseClient._init();
  DatabaseClient._init();

  late final Db client;

  static Future<DatabaseClient> create({bool initializing = false, String? uri}) async {
    if (initializing) {
      if (uri != null) {
        _instance.client = await Db.create(uri);
      } else {
        throw UnsupportedError("Cannot initialize a database client without a URI.");
      }
    }

    if (!_instance.client.isConnected) {
      await _instance.client.open();
    }

    return _instance;
  }
}

Future<DatabaseClient> _dbClass = DatabaseClient.create(initializing: false);
final _defaultData = {
  "onJoinEnabled": true,
  "fuzzyMatchPercent": 100,
  "rules": [
    {"type": 1, "enabled": true, "action": ActionEnum.kick.value}
  ]
};

Future<WriteResult> insertNewGuild({required BigInt serverID}) async {
  var _db = await _dbClass;
  DbCollection collection = _db.client.collection("guilds");
  return await collection
      .updateOne({"_id": serverID.toString()}, {"\$setOnInsert": _defaultData}, upsert: true);
}

Future<JsonData> fetchGuildData(
    {required BigInt serverID, List<String>? fields, bool generateOnNull = false}) async {
  var _db = await _dbClass;
  DbCollection collection = _db.client.collection("guilds");
  JsonData? data = await collection.findOne({"_id": serverID.toString()});

  if (data == null) {
    if (generateOnNull) {
      var newData = await insertNewGuild(serverID: serverID);
      if (newData.document != null) {
        return newData.document!;
      } else {
        return {};
      }
    }
    return {};
  }

  if (fields != null && fields.isNotEmpty) {
    data.removeWhere((key, value) => !(key == "_id" || fields.contains(key)));
  }

  return data;
}

Future<WriteResult> updateGuildConfig(
    {required BigInt serverID,
    BigInt? logchannelID,
    bool? onJoinEvent,
    int? fuzzyMatchPercent,
    Action? phishingMatchAction,
    bool? phishingMatchEnabled}) async {
  var _db = await _dbClass;
  DbCollection collection = _db.client.collection("guilds");

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

  return await collection.updateOne(queryMap, {"\$set": updateMap});
}

Future<List<JsonData>> fetchGuildRules({required BigInt serverID}) async {
  var _db = await _dbClass;
  DbCollection collection = _db.client.collection("guilds");
  List<JsonData> data = await (collection
      .modernFind(filter: {"_id": serverID.toString(), "rules.type": 0}, projection: {"rules": 1})).toList();

  if (data.isEmpty) {
    return [];
  } else {
    return data;
  }
}

Future<bool> insertGuildRule({required BigInt serverID, required Rule rule}) async {
  var _db = await _dbClass;
  DbCollection collection = _db.client.collection("guilds");
  WriteResult result = await collection.updateOne({
    "_id": serverID.toString()
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

  return result.isSuccess;
}

Future<bool> removeGuildRule({required BigInt serverID, required String ruleID}) async {
  var _db = await _dbClass;
  DbCollection collection = _db.client.collection("guilds");
  WriteResult result = await collection.updateOne({
    "_id": serverID.toString()
  }, {
    "\$pull": {
      'rules': {"ruleID": ruleID}
    }
  });

  return result.isSuccess;
}
