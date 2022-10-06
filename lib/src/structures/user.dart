class User {
  BigInt userID;
  String username;
  String? nickname;
  List<BigInt> roles = [];

  User({required this.userID, required this.username, this.nickname, List<BigInt>? roles}) {
    if (roles != null) this.roles = roles;
  }
}

class UserBuilder {
  late BigInt userID;
  late String username;
  late String? nickname;
  List<BigInt> roles = [];

  UserBuilder();

  void setUserID(BigInt userID) => this.userID = userID;

  void setUsername(String username) => this.username = username;

  void setNickname(String? nickname) => this.nickname = nickname;

  void addRole(BigInt roleID) => roles.add(roleID);

  User build() => User(userID: userID, username: username, nickname: nickname, roles: roles);
}
