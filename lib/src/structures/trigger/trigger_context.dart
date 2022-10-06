import 'trigger_source.dart';
import '../user.dart';
import '../server.dart';

class TriggerContent {
  EventSource eventSource;
  User user;
  Server server;

  TriggerContent({required this.eventSource, required this.user, required this.server});
}

class TriggerContentBuilder {
  late EventSource eventSource;
  late User user;
  late Server server;

  TriggerContentBuilder();

  void setEventSource(EventSource eventSource) => this.eventSource = eventSource;

  void setUser(User user) => this.user = user;

  void setServer(Server server) => this.server = server;

  TriggerContent build() => TriggerContent(eventSource: eventSource, user: user, server: server);
}
