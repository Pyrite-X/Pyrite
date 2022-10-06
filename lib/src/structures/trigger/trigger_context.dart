import 'trigger_source.dart';
import '../user.dart';
import '../server.dart';

class TriggerContext {
  EventSource eventSource;
  User user;
  Server server;

  TriggerContext({required this.eventSource, required this.user, required this.server});
}

class TriggerContextBuilder {
  late EventSource eventSource;
  late User user;
  late Server server;

  TriggerContextBuilder();

  void setEventSource(EventSource eventSource) => this.eventSource = eventSource;

  void setUser(User user) => this.user = user;

  void setServer(Server server) => this.server = server;

  TriggerContext build() => TriggerContext(eventSource: eventSource, user: user, server: server);
}
