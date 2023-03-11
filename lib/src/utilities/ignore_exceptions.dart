import 'dart:isolate';

import 'package:logging/logging.dart';

final Logger logger = Logger("IE");
final errorPort = ReceivePort();

void ignoreExceptions() {
  errorPort.listen((message) {
    logger.shout(message);
  });

  Isolate.current.setErrorsFatal(false);
  Isolate.current.addErrorListener(errorPort.sendPort);
}

void allowExceptions() {
  Isolate.current.setErrorsFatal(true);
  Isolate.current.removeErrorListener(errorPort.sendPort);
}
