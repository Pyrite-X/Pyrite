// ignore_for_file: non_constant_identifier_names

import 'package:nyxx/nyxx.dart' show EmbedBuilder, DiscordColor;

final _INFO_COLOR = DiscordColor.parseHexString("4D346D");
final _SUCCESS_COLOR = DiscordColor.parseHexString("69c273");
final _WARNING_COLOR = DiscordColor.parseHexString("ffc551");
final _ERROR_COLOR = DiscordColor.parseHexString("ff5151");

/// Purple colored embed with current time as timestamp.
EmbedBuilder infoEmbed() => EmbedBuilder(color: _INFO_COLOR, timestamp: DateTime.now(), fields: []);

/// Green colored embed with current time as timestamp.
EmbedBuilder successEmbed() => EmbedBuilder(color: _SUCCESS_COLOR, timestamp: DateTime.now(), fields: []);

/// Yellow colored embed with current time as timestamp.
EmbedBuilder warningEmbed() => EmbedBuilder(color: _WARNING_COLOR, timestamp: DateTime.now(), fields: []);

/// Red colored embed with current time as timestamp.
EmbedBuilder errorEmbed() => EmbedBuilder(color: _ERROR_COLOR, timestamp: DateTime.now(), fields: []);
