import 'package:unorm_dart/unorm_dart.dart' as unorm;

class User {
  BigInt userID;
  late String username;
  String tag;
  String? globalName;
  String? nickname;
  List<BigInt> roles = [];

  User(
      {required this.userID,
      required String username,
      required this.tag,
      String? globalName,
      String? nickname,
      List<BigInt>? roles}) {
    if (roles != null) this.roles = roles;

    /// Normalize the output to get rid of custom fonts/styles that could bypass matching.
    this.username = unorm.nfkc(username);
    if (nickname != null) this.nickname = unorm.nfkc(nickname);

    if (globalName != null) this.globalName = globalName;
  }
}

class UserBuilder {
  late BigInt userID;
  late String username;
  late String tag;
  String? globalName;
  String? nickname;
  List<BigInt> roles = [];

  UserBuilder();

  void setUserID(BigInt userID) => this.userID = userID;

  void setUsername(String username) => this.username = username;

  void setTag(String tag) => this.tag = tag;

  void setGlobalName(String? globalName) => this.globalName = globalName;

  void setNickname(String? nickname) => this.nickname = nickname;

  void addRole(BigInt roleID) => roles.add(roleID);

  User build() => User(
      userID: userID, username: username, tag: tag, globalName: globalName, nickname: nickname, roles: roles);
}
