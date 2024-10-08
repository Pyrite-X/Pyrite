import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:string_similarity/string_similarity.dart';

import '../../structures/trigger/trigger_context.dart';
import 'check_result.dart';

List<String> phishingList = [];
Logger _logger = Logger("Bot List");

Future<void> loadPhishingList() async {
  try {
    var result =
        await http.get(Uri.parse("https://raw.githubusercontent.com/Pyrite-X/Bot-List/main/botlist.json"));
    var resultBody = jsonDecode(result.body);

    var botList = resultBody["bots"];
    if (phishingList.length != botList.length) {
      phishingList = [...botList];
      _logger.info("The bot list has been updated. There are ${phishingList.length} elements in the list.");
    } else {
      // Only send the msg if we're debugging for some reason.
      _logger.fine("The bot list has not been updated because there are no new elements to add.");
    }
  } catch (e) {
    _logger.severe("The bot list could not be updated due to an exception.", e);
  }
}

CheckPhishResult checkPhishingList(TriggerContext context) {
  String? matchString;
  String? userString;
  if (context.server.checkPhishingList != null && !context.server.checkPhishingList!) {
    return CheckPhishResult(match: false);
  }

  int? fuzzyMatchPercent = context.server.fuzzyMatchPercent;
  // Set to 100 (no fuzzy matching) if not found.
  fuzzyMatchPercent ??= 100;
  String lowercaseUsername = context.user.username.toLowerCase();
  String? lowercaseGlobalName = context.user.globalName?.toLowerCase();
  String? lowercaseNickname = context.user.nickname?.toLowerCase();

  bool usernameCheck = false;
  bool globalNameCheck = false;
  bool nicknameCheck = false;

  double similarity = 100;
  for (String botName in phishingList) {
    String lowerBotName = botName.toLowerCase();

    usernameCheck = lowerBotName == lowercaseUsername;
    globalNameCheck = lowerBotName == lowercaseGlobalName;
    nicknameCheck = lowerBotName == lowercaseNickname;

    if (usernameCheck || nicknameCheck || globalNameCheck) {
      matchString = botName;

      userString = usernameCheck
          ? context.user.username
          : globalNameCheck
              ? context.user.globalName
              : context.user.nickname;

      break;
    }

    if (fuzzyMatchPercent != 100) {
      double usernameSim = lowercaseUsername.similarityTo(lowerBotName);
      double globalNameSim = lowercaseGlobalName.similarityTo(lowerBotName);
      double nicknameSim = lowercaseNickname.similarityTo(lowerBotName);

      usernameCheck = usernameSim * 100 >= fuzzyMatchPercent;
      globalNameCheck = globalNameSim * 100 >= fuzzyMatchPercent;
      nicknameCheck = nicknameSim * 100 >= fuzzyMatchPercent;

      if (usernameCheck || globalNameCheck || nicknameCheck) {
        similarity = usernameCheck
            ? usernameSim * 100
            : globalNameCheck
                ? globalNameSim * 100
                : nicknameSim * 100;

        matchString = botName;

        userString = usernameCheck
            ? context.user.username
            : globalNameCheck
                ? context.user.globalName
                : context.user.nickname;

        break;
      }
    }
  }

  String? nameStringType;
  if (usernameCheck) {
    nameStringType = "Username";
  } else if (globalNameCheck) {
    nameStringType = "Display Name";
  } else if (nicknameCheck) {
    nameStringType = "Nickname";
  }

  return (matchString == null)
      ? CheckPhishResult(match: false)
      : CheckPhishResult(
          match: true,
          nameStringType: nameStringType,
          matchingString: matchString,
          fuzzyMatchPercent: similarity,
          userString: userString);
}
