class ScanMode {
  late String textValue;

  List<ScanModeOptions> enumList = [];

  ScanMode.fromString(String input) {
    textValue = input;

    List<String> splitInput = input.split(',');
    splitInput.forEach((element) {
      enumList.add(ScanModeOptions.fromString(element));
    });
  }

  bool containsType(ScanModeOptions typeEnum) => enumList.contains(typeEnum);
}

enum ScanModeOptions {
  phish,
  rules;

  factory ScanModeOptions.fromString(String value) {
    switch (value) {
      case "phish":
        return ScanModeOptions.phish;
      case "rules":
        return ScanModeOptions.rules;
      default:
        throw UnimplementedError("The type $value is not implemented as a Scan type.");
    }
  }
}
