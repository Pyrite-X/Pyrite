import '../scan_types.dart';

class EventSource {
  EventSourceType sourceType;
  ScanMode? scanningMode;

  EventSource({required this.sourceType, this.scanningMode});
}

enum EventSourceType { join, scan }
