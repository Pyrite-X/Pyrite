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
  DatabaseClient _client = DatabaseClient();

  Future<void> createServer(Server server) async {}
  Future<void> updateConfiguration(
      {BigInt? logchannelID, bool? joinEventHandling, Action? joinAction}) async {}
  Future<void> getServer(BigInt serverID) async {}
}

class RuleQueries {
  DatabaseClient _client = DatabaseClient();

  Future<void> createRule(Server server, Rule rule) async {}
  Future<void> deleteRule(Server server, String ruleID) async {}
  Future<void> getServerRules(Server server) async {}
}

class PhishListQueries {
  DatabaseClient _client = DatabaseClient();

  ///TODO: Create phishinglist class to handle config info.
  Future<void> createPhishingConfig(Server server) async {}
  Future<void> updateConfiguration(
      {Action? action, bool? enabled, List<BigInt>? excludedRoles, int? fuzzyMatchPercent}) async {}
}

class PremiumQueries {
  DatabaseClient _client = DatabaseClient();

  Future<void> addEntry(BigInt userID, String code) async {}
  Future<void> updateTransfer(BigInt userID, BigInt recipientID) async {}
  Future<void> revokeTransfer(BigInt userID) async {}
  Future<void> updateTier(BigInt userID) async {}
}
