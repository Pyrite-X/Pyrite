import 'dart:async';
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
  if (context.server.checkPhishingList != null && !context.server.checkPhishingList!) {
    return CheckPhishResult(match: false);
  }

  int? fuzzyMatchPercent = context.server.fuzzyMatchPercent;
  String lowercaseUsername = context.user.username.toLowerCase();
  String? lowercaseNickname = context.user.nickname?.toLowerCase();

  for (String name in phishingList) {
    bool usernameCheck = name.toLowerCase() == lowercaseUsername;
    bool nicknameCheck = name.toLowerCase() == lowercaseNickname;
    if (usernameCheck || nicknameCheck) {
      matchString = name;
      break;
    }

    if (fuzzyMatchPercent != null && fuzzyMatchPercent != 100) {
      usernameCheck = lowercaseUsername.similarityTo(name.toLowerCase()) * 100 >= fuzzyMatchPercent;
      nicknameCheck = lowercaseNickname.similarityTo(name.toLowerCase()) * 100 >= fuzzyMatchPercent;
      if (usernameCheck || nicknameCheck) {
        matchString = name;
        break;
      }
    }
  }

  return (matchString == null)
      ? CheckPhishResult(match: false)
      : CheckPhishResult(match: true, matchingString: matchString);
}
