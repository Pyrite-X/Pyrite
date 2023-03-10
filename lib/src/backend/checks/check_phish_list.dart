import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:string_similarity/string_similarity.dart';

import '../../structures/trigger/trigger_context.dart';
import 'check_result.dart';

List<String> phishingList = [];
void loadPhishingList() async {
  var result =
      await http.get(Uri.parse("https://raw.githubusercontent.com/Pyrite-X/Bot-List/main/botlist.json"));
  var resultBody = jsonDecode(result.body);

  try {
    var botList = resultBody["bots"];
    phishingList = [...botList];
    print("Phishing list has been updated. There are ${phishingList.length} elements in the list.");
  } catch (e) {
    print("Error loading the phishing list: $e");
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
  String? lowercaseNickname = context.user.nickname?.toLowerCase();

  double similarity = 100;
  for (String botName in phishingList) {
    String lowerBotName = botName.toLowerCase();
    bool usernameCheck = lowerBotName == lowercaseUsername;
    bool nicknameCheck = lowerBotName == lowercaseNickname;
    if (usernameCheck || nicknameCheck) {
      matchString = botName;
      userString = usernameCheck ? context.user.username : context.user.nickname;
      break;
    }

    if (fuzzyMatchPercent != 100) {
      double luSim = lowercaseUsername.similarityTo(lowerBotName);
      double lnSim = lowercaseNickname.similarityTo(lowerBotName);

      usernameCheck = luSim * 100 >= fuzzyMatchPercent;
      nicknameCheck = lnSim * 100 >= fuzzyMatchPercent;

      if (usernameCheck || nicknameCheck) {
        similarity = usernameCheck ? luSim * 100 : lnSim * 100;
        matchString = botName;
        userString = usernameCheck ? context.user.username : context.user.nickname;
        break;
      }
    }
  }

  return (matchString == null)
      ? CheckPhishResult(match: false)
      : CheckPhishResult(
          match: true, matchingString: matchString, fuzzyMatchPercent: similarity, userString: userString);
}
