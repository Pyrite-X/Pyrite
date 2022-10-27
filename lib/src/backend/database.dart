import 'package:edgedb/edgedb.dart';

import '../structures/action.dart';
import '../structures/rule.dart';
import '../structures/server.dart';

class DatabaseClient {
  static final DatabaseClient _instance = DatabaseClient._init();
  DatabaseClient._init();

  late final Client client;

  factory DatabaseClient({bool initializing = false}) {
    if (initializing) {
      _instance.client = createClient();
    }

    return _instance;
  }
}

class ServerQueries {
  DatabaseClient _db = DatabaseClient();

  Future<void> createServer(Server server) async {
    String queryString = r"""insert Server {
      serverID := <int64>$id
    } unless conflict on .serverID""";
    await _db.client.execute(queryString, {'id': server.serverID});
  }

  Future<void> updateConfiguration(
      {required BigInt serverID, BigInt? logchannelID, bool? joinEventHandling, Action? joinAction}) async {
    StringBuffer buffer = StringBuffer();
    buffer.writeln("update Server");
    buffer.writeln(r"filter .serverID = <int64>$id");
    buffer.writeln("set {");
    if (logchannelID != null) buffer.writeln(r"logchannelID := <int64>$logchannelID,");
    if (joinEventHandling != null) buffer.writeln(r"onJoinEnabled := <bool>$joinEventHandling,");
    if (joinAction != null) buffer.writeln(r"joinAction := <int16>$joinAction");
    buffer.write("}");

    await _db.client.execute(buffer.toString(), {
      "id": serverID.toInt(),
      "logchannelID": logchannelID,
      "joinEventHandling": joinEventHandling,
      "joinAction": joinAction
    });
  }

  Future<dynamic> getServer(BigInt serverID) async {
    String queryString = r"""select Server {
      serverID,
      joinAction,
      onJoinEnabled,
      logchannelID
    } filter .serverID = <int64>$0""";
    return await _db.client.querySingle(queryString, [serverID.toInt()]);
  }
}

class RuleQueries {
  DatabaseClient _db = DatabaseClient();

  Future<void> createRule(Server server, Rule rule) async {
    Map<String, dynamic> queryArgs = {
      "ruleID": rule.ruleID,
      "authorID": rule.authorID.toInt(),
      "pattern": rule.pattern,
      "regex": rule.regex,
      "serverID": server.serverID.toInt()
    };

    String queryString = r"""insert Rule {
      ruleID := <str>$ruleID,
      authorID := <int64>$authorID,
      pattern := <str>$pattern,
      isRegex := <bool>$regex,
      server := (
        select Server
        filter .serverID = <int64>$serverID
        limit 1
      ),""";

    if (rule.excludedRoles != null && rule.excludedRoles!.isNotEmpty) {
      queryString += r"excludedRoles := <array<int64>>$excludedRoles";
      List<int> toIntList = [];
      rule.excludedRoles!.forEach((element) => toIntList.add(element.toInt()));
      queryArgs["excludedRoles"] = toIntList;
    }

    queryString += "}";

    await _db.client.query(queryString, queryArgs);
  }

  Future<void> deleteRule(Server server, String ruleID) async {
    String queryString = r"""delete Rule
      filter .ruleID = <str>$ruleID and .server.serverID = <int64>$serverID""";

    await _db.client.query(queryString, {"ruleID": ruleID, "serverID": server.serverID.toInt()});
  }

  Future<dynamic> getRule(Server server, String ruleID) async {
    String queryString = r"""select Rule {
      ruleID,
      authorID,
      pattern,
      isRegex,
      server,
      excludedRoles
    }
    filter .ruleID = <str>$ruleID and .server.serverID = <int64>$serverID""";

    return await _db.client.query(queryString, {"ruleID": ruleID, "serverID": server.serverID.toInt()});
  }

  Future<List<dynamic>> getAllServerRules(Server server) async {
    String queryString = r"""select Rule {
      ruleID,
      authorID,
      pattern,
      isRegex,
      server,
      excludedRoles
    }
    filter .server.serverID = <int64>$serverID""";

    return await _db.client.query(queryString, {"serverID": server.serverID.toInt()});
  }
}

class PhishListQueries {
  DatabaseClient _db = DatabaseClient();

  ///TODO: Create phishinglist class to handle config info.
  Future<void> createPhishingConfig(Server server) async {}
  Future<void> updateConfiguration(
      {Action? action, bool? enabled, List<BigInt>? excludedRoles, int? fuzzyMatchPercent}) async {}
}

class PremiumQueries {
  DatabaseClient _db = DatabaseClient();

  Future<void> addEntry(BigInt userID, String code) async {}
  Future<void> updateTransfer(BigInt userID, BigInt recipientID) async {}
  Future<void> revokeTransfer(BigInt userID) async {}
  Future<void> updateTier(BigInt userID) async {}
}
