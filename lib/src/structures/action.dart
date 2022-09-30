class Action {
  late int bitwiseValue;
  late String textValue;

  List<ActionEnum> enumList = [];

  Action.fromString(String input) {
    textValue = input;
    bitwiseValue = 0;

    var splitString = input.split(",");
    splitString.forEach((element) {
      ActionEnum action = ActionEnum.fromString(element);
      enumList.add(action);
      bitwiseValue = action.value | bitwiseValue;
    });
  }

  bool containsValue(int input) {
    return (bitwiseValue & input) != 0;
  }
}

class ActionEnumString {
  static String kick = "Kick the matching user.";
  static String ban = "Ban the matching user.";
  static String log = "Log the match to the set log channel.";

  static String getEnumString(ActionEnum ae) {
    switch (ae) {
      case ActionEnum.kick:
        return kick;
      case ActionEnum.ban:
        return ban;
      case ActionEnum.log:
        return log;
    }
  }

  static List<String> getStringsFromAction(Action value) {
    List<String> result = [];

    if (value.containsValue(1 << 0)) {
      result.add(kick);
    }

    if (value.containsValue(1 << 1)) {
      result.add(ban);
    }

    if (value.containsValue(1 << 2)) {
      result.add(log);
    }

    return result;
  }
}

enum ActionEnum {
  kick(1 << 0), // 1
  ban(1 << 1), // 2
  log(1 << 2); // 4

  const ActionEnum(this.value);
  final int value;

  factory ActionEnum.fromString(String value) {
    switch (value) {
      case "kick":
        return ActionEnum.kick;
      case "ban":
        return ActionEnum.ban;
      case "log":
        return ActionEnum.log;
      default:
        throw UnimplementedError("The type $value is not implemented as a Action type.");
    }
  }
}
