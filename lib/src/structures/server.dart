import 'dart:convert';

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
  List<String> excludedNames = [];

  Server({
    required this.serverID,
    this.logchannelID,
    this.onJoinEnabled,
    this.fuzzyMatchPercent,
    this.checkPhishingList,
    this.phishingMatchAction,
    List<Rule>? rules,
    List<BigInt>? excludedRoles,
    List<String>? excludedNames,
  }) {
    if (rules != null) this.rules = rules;
    if (excludedRoles != null) this.excludedRoles = excludedRoles;
    if (excludedNames != null) this.excludedNames = excludedNames;
  }

  /// Specifically from a database representation of the server data.
  Server.fromJson({required JsonData data}) {
    if (data.containsKey("_id")) {
      serverID = BigInt.parse(data["_id"].toString());
    } else if (data.containsKey("serverID")) {
      serverID = BigInt.parse(data["serverID"].toString());
    }

    logchannelID = BigInt.tryParse(data["logchannelID"].toString());
    onJoinEnabled = data["onJoinEnabled"].runtimeType == String
        ? data["onJoinEnabled"].toString() == "true"
        : data["onJoinEnabled"];
    fuzzyMatchPercent = data["fuzzyMatchPercent"].runtimeType == int
        ? data["fuzzyMatchPercent"]
        : int.tryParse(data["fuzzyMatchPercent"].toString());

    if (data["rules"] != null) {
      Iterable<dynamic> ruleList =
          data["rules"].runtimeType == String ? jsonDecode(data["rules"]) : data["rules"];

      var phishEntry = ruleList.firstWhere(
        (element) => element["type"] == 1,
        orElse: () => {} as JsonData,
      );
      if ((phishEntry as JsonData).isNotEmpty) {
        checkPhishingList = phishEntry["enabled"].runtimeType == String
            ? phishEntry["enabled"] == "true"
            : phishEntry["enabled"];
        phishingMatchAction = Action.fromInt(phishEntry["action"]);
      }

      var ruleIterator = ruleList.where((element) => element["type"] == 0);
      rules = [for (var rule in ruleIterator) Rule.fromJson(rule)];
    }

    if (data["whitelist"] != null) {
      JsonData whitelist = data["whitelist"];
      if (whitelist.containsKey("roles")) {
        whitelist["roles"] =
            (whitelist["roles"].runtimeType == String) ? jsonDecode(whitelist["roles"]) : whitelist["roles"];
        excludedRoles = [for (var role in whitelist["roles"]) BigInt.parse(role)];
      }

      if (whitelist.containsKey("names")) {
        whitelist["names"] =
            (whitelist["names"].runtimeType == String) ? jsonDecode(whitelist["names"]) : whitelist["names"];
        excludedNames = [...whitelist["names"]];
      }
    }
  }

  /// Creates a json representation of a Server without any custom rules, nor any whitelist configuration.
  Map<String, dynamic> toJson() {
    Map<String, dynamic> output = {
      'serverID': serverID.toString(),
      'logchannelID': logchannelID.toString(),
      'onJoinEnabled': onJoinEnabled,
      'fuzzyMatchPercent': fuzzyMatchPercent,
      'rules': [
        jsonEncode({'type': 1, 'enabled': checkPhishingList, 'action': phishingMatchAction?.bitwiseValue})
      ]
    };

    return output;
  }

  Map<String, dynamic> toJsonCustom({bool withRules = true, bool withWhitelist = true}) {
    var baseJson = toJson();

    if (withRules) {
      List<String> ruleList = baseJson["rules"];
      for (Rule rule in rules) {
        ruleList.add(jsonEncode(rule.toJson()));
      }
      baseJson["rules"] = ruleList;
    }

    if (withWhitelist) {
      JsonData whitelist = {};
      if (excludedRoles.isNotEmpty) {
        List<String> roleList = [for (BigInt role in excludedRoles) role.toString()];
        whitelist["roles"] = jsonEncode(roleList);
      }

      if (excludedNames.isNotEmpty) {
        whitelist["roles"] = jsonEncode(excludedNames);
      }

      baseJson["whitelist"] = jsonEncode(whitelist);
    }

    return baseJson;
  }
}
