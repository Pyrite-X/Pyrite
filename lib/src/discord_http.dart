import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:onyx/onyx.dart';

class DiscordHTTP {
  /// Base layout taken from myself at https://github.com/One-Nub/Lirx.
  /// I would've extended the client from there, but the user agent would be wrong
  /// and the authorization string is private, as well as all the header building methods.
  ///
  /// There is no ratelimiting here... Needs to be resolved, or a proxy will need to be thrown
  /// in front that handles ratelimits for me... Probably will use nirn.

  static const String _userAgent = "Pyrite (https://github.com/One-Nub/Pyrite, 0.0.1)";

  final String discordURL;

  /// Version of the API that Pyrite will be using.
  final String apiVersion;

  /// The Bot token that will be used to authorize.
  final String authToken;

  /// The ID of the application, used for making REST requests.
  final BigInt applicationID;

  /// Scheme used to send the request, http or https.
  final String scheme;

  /// Authorization string consisting of the [authToken] with the proper syntax for Discord.
  late final String _authorizationStr;

  /// Instantiates the DiscordHTTP class.
  ///
  /// [authToken] is the token used to authenticate requests sent to Discord, and should be the
  /// token for a Bot account. <br>
  /// [applicationID] is the application ID for the bot/application. <br>
  /// [discordURL] is the primary domain that will be used when sending requests to Discord.
  /// Defaults to "discord.com/api/". If this is changed, it must include the final "/". <br>
  /// [apiVersion] will be the version of Discord's API that will be used. Defaults to "v10".
  DiscordHTTP(
      {required this.authToken,
      required this.applicationID,
      this.discordURL = "discord.com",
      this.apiVersion = "v10",
      this.scheme = "https"}) {
    _authorizationStr = "Bot $authToken";
  }

  /// Build the headers that will be sent in the REST request.
  Map<String, String> _buildHeaders() {
    return {
      "Accept": "application/json",
      "Authorization": _authorizationStr,
      "User-Agent": _userAgent,
      "Content-Type": "application/json"
    };
  }

  Future<http.Response> banUser({required BigInt guildID, required BigInt userID, int? deleteSeconds}) async {
    UriBuilder builder = UriBuilder(scheme: scheme, host: discordURL);
    builder.setPath("/api/$apiVersion/guilds/$guildID/bans/$userID");

    var uri = builder.build();
    return await http.put(uri, headers: _buildHeaders(), body: {
      "delete_message_seconds": deleteSeconds ??= 600 //1 hour by default
    });
  }

  Future<http.Response> kickUser({required BigInt guildID, required BigInt userID}) async {
    UriBuilder builder = UriBuilder(scheme: scheme, host: discordURL);
    builder.setPath("/api/$apiVersion/guilds/$guildID/members/$userID");

    var uri = builder.build();
    return await http.delete(uri, headers: _buildHeaders());
  }

  Future<http.Response> sendLogMessage({required BigInt channelID, required JsonData payload}) async {
    UriBuilder builder = UriBuilder(scheme: scheme, host: discordURL);
    builder.setPath("/api/$apiVersion/channels/$channelID/messages");

    var uri = builder.build();
    return await http.post(uri, headers: _buildHeaders(), body: jsonEncode(payload));
  }

  Future<http.Response> getUser({required BigInt userID}) async {
    UriBuilder builder = UriBuilder(scheme: scheme, host: discordURL);
    builder.setPath("/api/$apiVersion/users/$userID");

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
    builder.setQueryParameters({"limit": limit, "after": after});

    var uri = builder.build();
    return await http.get(uri, headers: _buildHeaders());
  }

  Future<http.Response> searchGuildMembers(
      {required BigInt guildID, required String query, int limit = 1}) async {
    UriBuilder builder = UriBuilder(scheme: scheme, host: discordURL);
    builder.setPath("/api/$apiVersion/guilds/$guildID/members/search");
    builder.setQueryParameters({"query": query, "limit": limit});

    var uri = builder.build();
    return await http.get(uri, headers: _buildHeaders());
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
