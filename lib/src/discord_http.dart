import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:onyx/onyx.dart';

/// Client to send REST requests to Discord.
///
/// Needs to be instantiated once with variables, after that it follows a singleton pattern.
class DiscordHTTP {
  static const String _userAgent = "Pyrite (https://github.com/One-Nub/Pyrite, 0.0.1)";

  static final DiscordHTTP _instance = DiscordHTTP._init();
  DiscordHTTP._init();

  late final String authToken;
  late final BigInt applicationID;
  late final String _authorizationStr;

  late String scheme = "https";
  late String discordURL = "discord.com";
  late String apiVersion = "v10";

  factory DiscordHTTP(
      {String? authToken, BigInt? applicationID, String? discordURL, String? apiVersion, String? scheme}) {
    if (authToken != null) {
      _instance.authToken = authToken;
      _instance._authorizationStr = "Bot $authToken";
    }
    if (applicationID != null) _instance.applicationID = applicationID;

    if (scheme != null) _instance.scheme = scheme;
    if (discordURL != null) _instance.discordURL = discordURL;
    if (apiVersion != null) _instance.apiVersion = apiVersion;

    return _instance;
  }

  /// Build the headers that will be sent in the REST request.
  Map<String, String> _buildHeaders({bool includeToken = true}) {
    var result = {"Accept": "application/json", "User-Agent": _userAgent, "Content-Type": "application/json"};
    if (includeToken) {
      result["Authorization"] = _authorizationStr;
    }

    return result;
  }

  Future<http.Response> banUser(
      {required BigInt guildID, required BigInt userID, int? deleteSeconds, String? logReason}) async {
    UriBuilder builder = UriBuilder(scheme: scheme, host: discordURL);
    builder.setPath("/api/$apiVersion/guilds/$guildID/bans/$userID");

    var uri = builder.build();
    var headers = _buildHeaders();
    if (logReason != null) {
      headers["X-Audit-Log-Reason"] = logReason;
    }
    return await http.put(uri, headers: headers, body: {
      "delete_message_seconds": deleteSeconds ??= 600 //1 hour by default
    });
  }

  Future<http.Response> kickUser({required BigInt guildID, required BigInt userID, String? logReason}) async {
    UriBuilder builder = UriBuilder(scheme: scheme, host: discordURL);
    builder.setPath("/api/$apiVersion/guilds/$guildID/members/$userID");

    var uri = builder.build();
    var headers = _buildHeaders();
    if (logReason != null) {
      headers["X-Audit-Log-Reason"] = logReason;
    }
    return await http.delete(uri, headers: headers);
  }

  Future<http.Response> sendMessage({required BigInt channelID, required JsonData payload}) async {
    UriBuilder builder = UriBuilder(scheme: scheme, host: discordURL);
    builder.setPath("/api/$apiVersion/channels/$channelID/messages");

    var uri = builder.build();
    return await http.post(uri, headers: _buildHeaders(), body: jsonEncode(payload));
  }

  Future<http.StreamedResponse> sendMessageWithFile(
      {required BigInt channelID, required http.MultipartFile file, JsonData? payload}) async {
    UriBuilder builder = UriBuilder(scheme: scheme, host: discordURL);
    builder.setPath("/api/$apiVersion/channels/$channelID/messages");

    var uri = builder.build();
    var request = http.MultipartRequest("POST", uri)..files.add(file);
    request.fields.addAll({"payload_json": jsonEncode(payload)});
    request.headers.addAll(_buildHeaders());

    return await request.send();
  }

  Future<http.Response> getUser({required BigInt userID}) async {
    UriBuilder builder = UriBuilder(scheme: scheme, host: discordURL);
    builder.setPath("/api/$apiVersion/users/$userID");

    var uri = builder.build();
    return await http.get(uri, headers: _buildHeaders());
  }

  Future<http.Response> getGuild({required BigInt guildID}) async {
    UriBuilder builder = UriBuilder(scheme: scheme, host: discordURL);
    builder.setPath("/api/$apiVersion/guilds/$guildID");

    var uri = builder.build();
    return await http.get(uri, headers: _buildHeaders());
  }

  Future<http.Response> getGuildMember({required BigInt guildID, required BigInt userID}) async {
    UriBuilder builder = UriBuilder(scheme: scheme, host: discordURL);
    builder.setPath("/api/$apiVersion/guilds/$guildID/members/$userID");

    var uri = builder.build();
    return await http.get(uri, headers: _buildHeaders());
  }

  Future<http.Response> listGuildMembers({required BigInt guildID, int limit = 1, BigInt? after}) async {
    if (after == null) after = BigInt.zero;

    UriBuilder builder = UriBuilder(scheme: scheme, host: discordURL);
    builder.setPath("/api/$apiVersion/guilds/$guildID/members");
    builder.setQueryParameters({"limit": "$limit", "after": "$after"});

    var uri = builder.build();
    return await http.get(uri, headers: _buildHeaders());
  }

  Future<http.Response> searchGuildMembers(
      {required BigInt guildID, required String query, int limit = 1}) async {
    UriBuilder builder = UriBuilder(scheme: scheme, host: discordURL);
    builder.setPath("/api/$apiVersion/guilds/$guildID/members/search");
    builder.setQueryParameters({"query": query, "limit": "$limit"});

    var uri = builder.build();
    return await http.get(uri, headers: _buildHeaders());
  }

  Future<http.Response> sendFollowupMessage(
      {required String interactionToken, required JsonData payload}) async {
    UriBuilder builder = UriBuilder(scheme: scheme, host: discordURL);
    builder.setPath("/api/$apiVersion/webhooks/$applicationID/$interactionToken");

    var uri = builder.build();
    return await http.post(uri, headers: _buildHeaders(), body: jsonEncode(payload));
  }

  Future<http.Response> editFollowupMessage(
      {required String interactionToken, required BigInt messageID, required JsonData payload}) async {
    UriBuilder builder = UriBuilder(scheme: scheme, host: discordURL);
    builder.setPath("/api/$apiVersion/webhooks/$applicationID/$interactionToken/messages/$messageID");

    var uri = builder.build();
    return await http.patch(uri, headers: _buildHeaders(), body: jsonEncode(payload));
  }
}

class UriBuilder {
  String? scheme;
  String? userInfo;
  String? host;
  int? port;
  String? path;
  Iterable<String>? pathSegments;
  String? query;
  Map<String, dynamic>? queryParameters;
  String? fragment;

  UriBuilder(
      {this.scheme,
      this.userInfo,
      this.host,
      this.port,
      this.path,
      this.pathSegments,
      this.query,
      this.queryParameters,
      this.fragment});

  void setScheme(String scheme) => this.scheme = scheme;

  void setUserInfo(String userInfo) => this.userInfo = userInfo;

  void setHost(String host) => this.host = host;

  void setPort(int port) => this.port = port;

  void setPath(String path) => this.path = path;

  void setPathSegments(Iterable<String> pathSegments) => this.pathSegments = pathSegments;

  void setQuery(String query) => this.query = query;

  void setQueryParameters(Map<String, dynamic> queryParameters) => this.queryParameters = queryParameters;

  void setFragment(String fragment) => this.fragment;

  Uri build() {
    return Uri(
        scheme: scheme,
        userInfo: userInfo,
        host: host,
        port: port,
        path: path,
        pathSegments: pathSegments,
        query: query,
        queryParameters: queryParameters,
        fragment: fragment);
  }
}
