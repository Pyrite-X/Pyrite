class ScanType {
  late String textValue;

  List<ScanTypeEnum> enumList = [];

  ScanType.fromString(String input) {
    textValue = input;

    List<String> splitInput = input.split(',');
    splitInput.forEach((element) {
      enumList.add(ScanTypeEnum.fromString(element));
    });
  }

  bool containsType(ScanTypeEnum typeEnum) => enumList.contains(typeEnum);
}

enum ScanTypeEnum {
  phish,
  rules;

  factory ScanTypeEnum.fromString(String value) {
    switch (value) {
      case "phish":
        return ScanTypeEnum.phish;
      case "rules":
        return ScanTypeEnum.rules;
      default:
        throw UnimplementedError("The type $value is not implemented as a Scan type.");
    }
  }
}
