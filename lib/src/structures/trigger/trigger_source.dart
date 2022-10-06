import '../scan_types.dart';

class EventSource {
  EventSourceType sourceType;
  ScanMode? scanningMode;

  EventSource({required this.sourceType});
}

enum EventSourceType { join, scan }
