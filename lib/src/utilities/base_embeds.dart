import 'package:nyxx/nyxx.dart' show EmbedBuilder, DiscordColor;

final _INFO_COLOR = DiscordColor.fromHexString("4D346D");
final _SUCCESS_COLOR = DiscordColor.fromHexString("69c273");
final _WARNING_COLOR = DiscordColor.fromHexString("ffc551");
final _ERROR_COLOR = DiscordColor.fromHexString("ff5151");

/// Purple colored embed with current time as timestamp.
EmbedBuilder infoEmbed() => EmbedBuilder(color: _INFO_COLOR, timestamp: DateTime.now());

/// Green colored embed with current time as timestamp.
EmbedBuilder successEmbed() => EmbedBuilder(color: _SUCCESS_COLOR, timestamp: DateTime.now());

/// Yellow colored embed with current time as timestamp.
EmbedBuilder warningEmbed() => EmbedBuilder(color: _WARNING_COLOR, timestamp: DateTime.now());

/// Red colored embed with current time as timestamp.
EmbedBuilder errorEmbed() => EmbedBuilder(color: _ERROR_COLOR, timestamp: DateTime.now());
