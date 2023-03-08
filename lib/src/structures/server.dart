import 'package:onyx/onyx.dart' show JsonData;

import 'action.dart';
import 'rule.dart';

class Server {
  late BigInt serverID;
  BigInt? logchannelID;
  bool? onJoinEnabled;
  int? fuzzyMatchPercent;
  bool? checkPhishingList;
  Action? phishingMatchAction;
  List<Rule> rules = [];
  List<BigInt> excludedRoles = [];

  Server(
      {required this.serverID,
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
  Server.fromJson({required JsonData data}) {
    this.serverID = BigInt.parse(data["_id"]);
    this.logchannelID = BigInt.tryParse(data["logchannelID"].toString());
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

      var ruleIterator = ruleList.where((element) => element["type"] == 0);
      List<Rule> convertedRuleList = [];
      ruleIterator.forEach((element) {
        convertedRuleList.add(Rule.fromJson(element));
      });
      this.rules = convertedRuleList;
    }

    if (data["excludedRoles"] != null) {
      List<dynamic> roleList = data["excludedRoles"];
      roleList.forEach((element) => excludedRoles.add(BigInt.parse(element)));
    }
  }

  /// Creates a json representation of a Server without any custom rules.
  Map<String, dynamic> toJson() {
    Map<String, dynamic> output = {
      'serverID': serverID.toString(),
      'logchannelID': logchannelID.toString(),
      'onJoinEnabled': onJoinEnabled,
      'fuzzyMatchPercent': fuzzyMatchPercent,
      'rules': [
        {'type': 1, 'enabled': checkPhishingList, 'action': phishingMatchAction?.bitwiseValue}
      ]
    };

    List<String> roleList = [];
    excludedRoles.forEach((element) => roleList.add(element.toString()));
    output['excludedRoles'] = roleList;

    return output;
  }

  Map<String, dynamic> toJsonWithCustomRules() {
    var baseJson = toJson();

    List<JsonData> ruleList = baseJson["rules"];
    for (Rule rule in rules) {
      ruleList.add(rule.toJson());
    }
    baseJson["rules"] = ruleList;

    return baseJson;
  }
}

class ServerBuilder {
  late BigInt serverID;
  BigInt? logchannelID;
  bool? onJoinEnabled;
  int? fuzzyMatchPercent;
  bool? checkPhishingList;
  Action? phishingMatchAction;
  List<Rule> rules = [];
  List<BigInt> excludedRoles = [];

  ServerBuilder();

  void setServerID(BigInt serverID) => this.serverID = serverID;

  void setLogChannelID(BigInt logchannelID) => this.logchannelID = logchannelID;

  void setOnJoinEnabled(bool onJoinEnabled) => this.onJoinEnabled = onJoinEnabled;

  void setFuzzyMatchPercent(int value) => this.fuzzyMatchPercent = value;

  void setPhishingListChecking(bool value) => this.checkPhishingList = value;

  void setPhishingMatchAction(Action action) => this.phishingMatchAction = action;

  void addRule(Rule rule) => rules.add(rule);

  void addExcludedRoleId(BigInt roleID) => excludedRoles.add(roleID);

  Server build() => Server(
      serverID: serverID,
      logchannelID: logchannelID,
      onJoinEnabled: onJoinEnabled,
      fuzzyMatchPercent: fuzzyMatchPercent,
      checkPhishingList: checkPhishingList,
      phishingMatchAction: phishingMatchAction,
      rules: rules,
      excludedRoles: excludedRoles);
}
