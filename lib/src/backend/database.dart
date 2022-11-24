import 'package:edgedb/edgedb.dart';

import '../structures/action.dart';
import '../structures/rule.dart';

class DatabaseClient {
  static final DatabaseClient _instance = DatabaseClient._init();
  DatabaseClient._init();

  late final Client client;

  factory DatabaseClient(
      {bool initializing = false, String? dsn, TLSSecurity tlsSecurity = TLSSecurity.defaultSecurity}) {
    if (initializing) {
      if (dsn != null) {
        _instance.client = createClient(dsn: dsn, tlsSecurity: tlsSecurity);
      } else {
        _instance.client = createClient(tlsSecurity: tlsSecurity);
      }

      _instance.client.ensureConnected();
    }

    return _instance;
  }
}

class ServerQueries {
  DatabaseClient _db = DatabaseClient();

  Future<void> createServer(BigInt serverID) async {
    String queryString = r"""insert Server {
      serverID := <int64>$id
    } unless conflict on .serverID""";
    await _db.client.execute(queryString, {'id': serverID.toInt()});
  }

  Future<void> updateConfiguration(
      {required BigInt serverID, BigInt? logchannelID, bool? joinEventHandling, Action? joinAction}) async {
    Map<String, dynamic> arguments = {"id": serverID.toInt()};
    StringBuffer buffer = StringBuffer();

    buffer.writeln("update Server");
    buffer.writeln(r"filter .serverID = <int64>$id");
    buffer.writeln("set {");
    if (logchannelID != null) {
      buffer.writeln(r"logchannelID := <int64>$logchannelID,");
      arguments["logchannelID"] = logchannelID.toInt();
    }
    if (joinEventHandling != null) {
      buffer.writeln(r"onJoinEnabled := <bool>$joinEventHandling,");
      arguments["joinEventHandling"] = joinEventHandling;
    }
    if (joinAction != null) {
      buffer.writeln(r"joinAction := <int16>$joinAction");
      arguments["joinAction"] = joinAction.bitwiseValue;
    }
    buffer.write("}");

    await _db.client.execute(buffer.toString(), arguments);
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

  Future<void> createRule(BigInt serverID, Rule rule) async {
    Map<String, dynamic> queryArgs = {
      "ruleID": rule.ruleID,
      "authorID": rule.authorID.toInt(),
      "pattern": rule.pattern,
      "regex": rule.regex,
      "serverID": serverID.toInt(),
      "action": rule.action.bitwiseValue
    };

    String queryString = r"""insert Rule {
      ruleID := <str>$ruleID,
      authorID := <int64>$authorID,
      pattern := <str>$pattern,
      isRegex := <bool>$regex,
      action := <int16>$action,
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

  Future<dynamic> deleteRule(BigInt serverID, String ruleID) async {
    String queryString = r"""delete Rule
      filter .ruleID = <str>$ruleID and .server.serverID = <int64>$serverID""";

    return await _db.client.querySingle(queryString, {"ruleID": ruleID, "serverID": serverID.toInt()});
  }

  Future<dynamic> getRule(BigInt serverID, String ruleID) async {
    String queryString = r"""select Rule {
      ruleID,
      authorID,
      pattern,
      isRegex,
      server,
      excludedRoles
    }
    filter .ruleID = <str>$ruleID and .server.serverID = <int64>$serverID""";

    return await _db.client.querySingle(queryString, {"ruleID": ruleID, "serverID": serverID.toInt()});
  }

  Future<List<dynamic>> getAllServerRules(BigInt serverID) async {
    String queryString = r"""select Rule {
      ruleID,
      authorID,
      action,
      pattern,
      isRegex,
      server,
      excludedRoles
    }
    filter .server.serverID = <int64>$serverID""";

    return await _db.client.query(queryString, {"serverID": serverID.toInt()});
  }
}

class PhishListQueries {
  DatabaseClient _db = DatabaseClient();

  /// Creates a default configuration for a [server].
  ///
  /// Utilizes the default for all other options, which is if matching is enabled,
  /// the action (which is to only kick by default), and a fuzzy match percentage.
  Future<void> createPhishingConfig(BigInt serverID) async {
    String queryString = r"""insert PhishingList {
      server := (
        select Server
        filter .serverID = <int64>$serverID
        limit 1
      )
    }""";

    await _db.client.execute(queryString, {"serverID": serverID.toInt()});
  }

  Future<void> updateConfiguration(
      {required BigInt serverID,
      Action? action,
      bool? enabled,
      List<BigInt>? excludedRoles,
      int? fuzzyMatchPercent}) async {
    if (action == null && enabled == null && excludedRoles == null && fuzzyMatchPercent == null) return;

    StringBuffer queryBuffer =
        StringBuffer(r"update PhishingList filter .server.serverID = <int64>$serverID set {");
    Map<String, dynamic> arguments = {"serverID": serverID.toInt()};

    if (action != null) {
      queryBuffer.writeln(r"action := <int16>$actionValue,");
      arguments["actionValue"] = action.bitwiseValue;
    }
    if (enabled != null) {
      queryBuffer.writeln(r"enabled := <bool>$enabled,");
      arguments["enabled"] = enabled;
    }
    if (excludedRoles != null) {
      queryBuffer.writeln(r"excludedRoles := <array<int64>>$excludedRoles,");
      List<int> intifiedList = [];
      excludedRoles.forEach((element) => intifiedList.add(element.toInt()));
      arguments["excludedRoles"] = intifiedList;
    }
    if (fuzzyMatchPercent != null) {
      queryBuffer.writeln(r"fuzzyPercent := <int16>$fuzzy");
      arguments["fuzzy"] = fuzzyMatchPercent;
    }

    queryBuffer.write("}");

    await _db.client.execute(queryBuffer.toString(), arguments);
  }
}

class PremiumQueries {
  DatabaseClient _db = DatabaseClient();

  Future<void> addEntry(BigInt userID, String code, String? tier) async {
    String queryString = r"""insert UserPremium {
      userID := <int64>$userID,
      code := <str>$code,
      tier := <optional str>$tier
    }""";

    Map<String, dynamic> arguments = {"userID": userID.toInt(), "code": code};
    if (tier != null) arguments["tier"] = tier;

    await _db.client.execute(queryString, arguments);
  }

  /// Returns one of 3 strings based upon existence: owner, transfer, or none.
  Future<String> checkUserExists(BigInt userID) async {
    String queryString =
        r"""with CU := (select UserPremium {userID, transferringTo} filter .userID = <int64>$id or .transferringTo = <int64>$id)
        select 'owner' if CU.userID ?= <int64>$id else
          'transfer' if CU.transferringTo ?= <int64>$id else
          'none';""";

    dynamic result = await _db.client.query(queryString, {"id": userID.toInt()});
    return result.first;
  }

  /// Returns an entry either if the userID is the owner of the premium, or if
  /// the userID is the recipient of a transfer.
  Future<dynamic> getUserEntry(BigInt userID) async {
    String queryString = r"""select UserPremium {
      userID,
      code,
      tier,
      transferringTo
    }
    filter .userID = <int64>$id or .transferringTo = <int64>$id""";

    return await _db.client.query(queryString, {"id": userID.toInt()});
  }

  Future<void> updateTransfer(BigInt userID, BigInt? recipientID) async {
    String queryString = r"""update UserPremium
      filter .userID = <int64>$userID
      set {
        transferringTo := <optional int64>$recipientID
      }""";

    Map<String, dynamic> arguments = {"userID": userID.toInt()};

    /// Will simply be cleared if there is no argument since it is optional in the query.
    if (recipientID != null) arguments["recipientID"] = recipientID.toInt();

    await _db.client.execute(queryString, arguments);
  }

  Future<void> updateTier(BigInt userID, String tier) async {
    String queryString = r"""update UserPremium
      filter .userID = <int64>$userID
      set {
        tier := <str>$tier
      }""";

    await _db.client.execute(queryString, {"userID": userID.toInt(), "tier": tier});
  }
}
