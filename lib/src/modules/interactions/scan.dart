import 'dart:collection';
import 'dart:convert';

import 'package:alfred/alfred.dart';
import 'package:onyx/onyx.dart';

import '../../discord_http.dart';
import '../../backend/storage.dart' as storage;
import '../../structures/scan_types.dart';
import '../../utilities/base_embeds.dart' as embeds;

ListQueue<QueuedServer> serverQueue = ListQueue();

class QueuedServer {
  BigInt serverID;
  BigInt channelID;
  BigInt authorID;
  ScanMode scanMode;
  QueuedServer(this.serverID, this.channelID, this.authorID, this.scanMode);

  @override
  bool operator ==(Object other) {
    if (other is BigInt) {
      return this.serverID == other;
    }

    return other is QueuedServer && this.serverID == other.serverID;
  }

  @override // This probably shouldn't be done, but we'll see if it breaks something? :)
  int get hashCode => Object.hash(this.serverID, this.serverID);
}

void scanCmd(Interaction interaction) async {
  var interactionData = interaction.data! as ApplicationCommandData;
  HttpRequest request = interaction.metadata["request"];

  // Defer with ephemeral message first.
  InteractionResponse response =
      InteractionResponse(InteractionResponseType.defer_message_response, {"flags": 1 << 6});
  await request.response.send(jsonEncode(response));

  DiscordHTTP discordHTTP = DiscordHTTP();

  var element = serverQueue.where((element) => element.serverID == interaction.guild_id);
  if (element.isNotEmpty) {
    await discordHTTP.sendFollowupMessage(interactionToken: interaction.token, payload: {
      "content":
          "Your server has already been queued by <@${element.first.authorID}>! Please continue waiting for your turn.",
      "flags": 1 << 6
    });
    return;
  }

  bool canRunScan = await storage.canRunScan(interaction.guild_id!);
  if (!canRunScan) {
    await discordHTTP.sendFollowupMessage(interactionToken: interaction.token, payload: {
      "content":
          "You have used up your available scans for the week. Please wait until Sunday (UTC), where they will be reset."
    });
    return;
  }

  ApplicationCommandOption subcommand = interactionData.options![0];
  ScanMode scanMode = ScanMode.fromString(subcommand.value);

  QueuedServer queuedServer = QueuedServer(interaction.guild_id!, interaction.channel_id!,
      BigInt.parse(interaction.member!["user"]["id"]), scanMode);
  serverQueue.add(queuedServer);

  String grammar = serverQueue.length == 1 ? "is now 1 server" : "are now ${serverQueue.length} servers";
  discordHTTP.sendFollowupMessage(
      interactionToken: interaction.token,
      payload: {"content": "Your server has been queued for scanning! There $grammar in the queue."});
}
