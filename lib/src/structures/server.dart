import 'package:onyx/onyx.dart' show JsonData;

import 'action.dart';
import 'rule.dart';

class Server {
  late BigInt serverID;
  BigInt ownerID;
  BigInt? logchannelID;
  bool? onJoinEnabled;
  int? fuzzyMatchPercent;
  bool? checkPhishingList;
  Action? phishingMatchAction;
  List<Rule> rules = [];
  List<BigInt> excludedRoles = [];

  Server(
      {required this.serverID,
      required this.ownerID,
      this.logchannelID,
      this.onJoinEnabled,
      this.fuzzyMatchPercent,
      this.checkPhishingList,
      this.phishingMatchAction,
      List<Rule>? rules,
      List<BigInt>? excludedRoles}) {
    if (rules != null) this.rules = rules;
    if (excludedRoles != null) this.excludedRoles = excludedRoles;
  }

  /// Specifically from a database representation of the server data.
  Server.fromJson({required JsonData data, required this.ownerID}) {
    this.serverID = data["_id"];
    this.logchannelID = data["logchannelID"];
    this.onJoinEnabled = data["onJoinEnabled"];
    this.fuzzyMatchPercent = data["fuzzyMatchPercent"];

    if (data["rules"] != null) {
      List<dynamic> ruleList = data["rules"];
      var phishEntry = ruleList.firstWhere(
        (element) => element["type"] == 1,
        orElse: () => {},
      );
      if ((phishEntry as Map).isNotEmpty) {
        this.checkPhishingList = phishEntry["enabled"];
        this.phishingMatchAction = Action.fromInt(phishEntry["action"]);
      }
    }

    if (data["excludedRoles"] != null) {
      List<dynamic> roleList = data["excludedRoles"];
      roleList.forEach((element) => excludedRoles.add(BigInt.from(element)));
    }
  }
}

class ServerBuilder {
  late BigInt serverID;
  late BigInt ownerID;
  BigInt? logchannelID;
  bool? onJoinEnabled;
  int? fuzzyMatchPercent;
  bool? checkPhishingList;
  Action? phishingMatchAction;
  List<Rule> rules = [];
  List<BigInt> excludedRoles = [];

  ServerBuilder();

  void setServerID(BigInt serverID) => this.serverID = serverID;

  void setOwnerID(BigInt ownerID) => this.ownerID = ownerID;

  void setLogChannelID(BigInt logchannelID) => this.logchannelID = logchannelID;

  void setOnJoinEnabled(bool onJoinEnabled) => this.onJoinEnabled = onJoinEnabled;

  void setFuzzyMatchPercent(int value) => this.fuzzyMatchPercent = value;

  void setPhishingListChecking(bool value) => this.checkPhishingList = value;

  void setPhishingMatchAction(Action action) => this.phishingMatchAction = action;

  void addRule(Rule rule) => rules.add(rule);

  void addExcludedRoleId(BigInt roleID) => excludedRoles.add(roleID);

  Server build() => Server(
      serverID: serverID,
      ownerID: ownerID,
      logchannelID: logchannelID,
      onJoinEnabled: onJoinEnabled,
      fuzzyMatchPercent: fuzzyMatchPercent,
      checkPhishingList: checkPhishingList,
      phishingMatchAction: phishingMatchAction,
      rules: rules,
      excludedRoles: excludedRoles);
}
