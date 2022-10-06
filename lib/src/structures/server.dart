import 'rule.dart';

class Server {
  BigInt serverID;
  BigInt ownerID;
  BigInt? logchannelID;
  List<Rule> rules = [];

  Server({required this.serverID, required this.ownerID, this.logchannelID, List<Rule>? rules}) {
    if (rules != null) this.rules = rules;
  }
}

class ServerBuilder {
  late BigInt serverID;
  late BigInt ownerID;
  BigInt? logchannelID;
  List<Rule> rules = [];

  ServerBuilder();

  void setServerID(BigInt serverID) => this.serverID = serverID;

  void setOwnerID(BigInt ownerID) => this.ownerID = ownerID;

  void setLogChannelID(BigInt logchannelID) => this.logchannelID = logchannelID;

  void addRule(Rule rule) => rules.add(rule);

  Server build() => Server(serverID: serverID, ownerID: ownerID, logchannelID: logchannelID, rules: rules);
}
