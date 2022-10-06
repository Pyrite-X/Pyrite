class EventSource {
  EventSourceType sourceType;

  EventSource({required this.sourceType});
}

enum EventSourceType { join, scan }
