import 'dart:collection';
import 'dart:convert';

import 'package:alfred/alfred.dart';
import 'package:http/http.dart' as http;
import 'package:nyxx/nyxx.dart';
import 'package:onyx/onyx.dart';

import '../../discord_http.dart';
import '../../backend/storage.dart' as storage;
import '../../structures/scan_types.dart';
import '../../structures/server.dart';
import '../../structures/user.dart';
import '../../utilities/base_embeds.dart' as embeds;

import '../../backend/checks/check.dart' as check;
import '../../structures/trigger/trigger_context.dart';
import '../../structures/trigger/trigger_source.dart';

ListQueue<QueuedServer> serverQueue = ListQueue();
QueuedServer? runningServer;

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

  if (runningServer?.serverID == interaction.guild_id) {
    await discordHTTP.sendFollowupMessage(interactionToken: interaction.token, payload: {
      "content": "Your server is currently being scanned! Please wait for it to finish.",
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
  discordHTTP.sendFollowupMessage(interactionToken: interaction.token, payload: {
    "content": "Your server has been queued for scanning! There $grammar in the queue.\n"
        "Status updates will be sent to your set log channel, or here if you have no log channel set."
  });
}

void queueHandler() async {
  if (serverQueue.isEmpty || runningServer != null) {
    return;
  }

  QueuedServer server = serverQueue.removeFirst();
  Server? serverObject = (server.scanMode.containsType(ScanModeOptions.rules))
      ? await storage.fetchGuildData(server.serverID, withRules: true)
      : await storage.fetchGuildData(server.serverID);

  if (serverObject != null) {
    if (serverObject.logchannelID != null) {
      server.channelID = serverObject.logchannelID!;
    }
  } else {
    //TODO: log that there was some issue
    return;
  }

  runningServer = server;
  DiscordHTTP discordHTTP = DiscordHTTP();

  EmbedBuilder embedBuilder = embeds.infoEmbed();
  embedBuilder.description = "Your server is now being scanned!";
  embedBuilder.addFooter((footer) {
    footer.text = "Guild ID: ${server.serverID}";
  });

  await discordHTTP.sendMessage(channelID: server.channelID, payload: {
    "embeds": [
      {...embedBuilder.build()}
    ]
  });

  scanServer(serverObject);
}

void scanServer(Server server) async {
  BigInt lastUserID = BigInt.zero;
  DiscordHTTP discordHTTP = DiscordHTTP();
  bool keepScanning = true;
  StringBuffer logBuffer = StringBuffer();

  TriggerContextBuilder contextBuilder = TriggerContextBuilder();
  EventSource eventSource =
      EventSource(sourceType: EventSourceType.scan, scanningMode: runningServer!.scanMode);

  contextBuilder.setEventSource(eventSource);
  contextBuilder.setServer(server);

  do {
    http.Response getMembers =
        await discordHTTP.listGuildMembers(guildID: runningServer!.serverID, limit: 1000, after: lastUserID);

    if (getMembers.statusCode == 429) {
      int statusCode = getMembers.statusCode;
      int retryCount = 0;
      while (statusCode == 429 && retryCount < 3) {
        // retry getting members 3 times.
        getMembers = await discordHTTP.listGuildMembers(
            guildID: runningServer!.serverID, limit: 1000, after: lastUserID);
        statusCode = getMembers.statusCode;
      }

      if (getMembers.statusCode == 429) {
        // log that there was some issue with getting the members - cancel the scan.
        runningServer = null;
        return;
      }
    } else if (getMembers.statusCode == 408) {
      print("something weird happened when getting guild members?");
    }

    Iterable<dynamic> body = jsonDecode(getMembers.body);
    for (var element in body) {
      User? user = _handleMember(element);
      if (user == null) {
        /// 'user' is a bot account, don't act on it.
        continue;
      }

      contextBuilder.setUser(user);
      check.checkUser(contextBuilder.build());
      lastUserID = user.userID;
    }

    if (body.length < 1000) {
      keepScanning = false;
    }
  } while (keepScanning);

  EmbedBuilder embedBuilder = embeds.infoEmbed();
  embedBuilder.description = "Your server has finished scanning!";
  embedBuilder.addFooter((footer) {
    footer.text = "Guild ID: ${server.serverID}";
  });

  await discordHTTP.sendMessage(channelID: runningServer!.channelID, payload: {
    "embeds": [
      {...embedBuilder.build()}
    ]
  });

  runningServer = null;
}

User? _handleMember(JsonData member) {
  UserBuilder userBuilder = UserBuilder();

  JsonData userJson = member["user"];
  if (userJson["bot"] != null && userJson["bot"]) {
    return null;
  }

  userBuilder.username = userJson["username"];
  userBuilder.nickname = member["nick"];
  userBuilder.tag = "${userBuilder.username}${userJson['discriminator']}";
  userBuilder.userID = BigInt.parse("${userJson['id']}");
  List<BigInt> roleList = [];
  (member["roles"] as List<dynamic>).forEach((element) => roleList.add(BigInt.parse("$element")));
  userBuilder.roles = roleList;

  return userBuilder.build();
}
