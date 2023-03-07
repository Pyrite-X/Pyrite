import 'action.dart';
import 'rule.dart';

class Server {
  BigInt serverID;
  BigInt ownerID;
  BigInt? logchannelID;
  bool? onJoinEnabled;
  int? fuzzyMatchPercent;
  bool? checkPhishingList;
  Action? phishingMatchAction;
  List<Rule> rules = [];

  Server(
      {required this.serverID,
      required this.ownerID,
      this.logchannelID,
      this.onJoinEnabled,
      this.fuzzyMatchPercent,
      this.checkPhishingList,
      this.phishingMatchAction,
      List<Rule>? rules}) {
    if (rules != null) this.rules = rules;
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

  ServerBuilder();

  void setServerID(BigInt serverID) => this.serverID = serverID;

  void setOwnerID(BigInt ownerID) => this.ownerID = ownerID;

  void setLogChannelID(BigInt logchannelID) => this.logchannelID = logchannelID;

  void setOnJoinEnabled(bool onJoinEnabled) => this.onJoinEnabled = onJoinEnabled;

  void setFuzzyMatchPercent(int value) => this.fuzzyMatchPercent = value;

  void setPhishingListChecking(bool value) => this.checkPhishingList = value;

  void setPhishingMatchAction(Action action) => this.phishingMatchAction = action;

  void addRule(Rule rule) => rules.add(rule);

  Server build() => Server(
      serverID: serverID,
      ownerID: ownerID,
      logchannelID: logchannelID,
      onJoinEnabled: onJoinEnabled,
      fuzzyMatchPercent: fuzzyMatchPercent,
      checkPhishingList: checkPhishingList,
      phishingMatchAction: phishingMatchAction,
      rules: rules);
}
