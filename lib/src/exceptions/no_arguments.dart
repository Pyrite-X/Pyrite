class NoArgumentsException implements Exception {
  final String message;

  NoArgumentsException(this.message);

  @override
  String toString() {
    return "NoArgumentsException: No arguments were found when at least 1 expected: $message";
  }
}
