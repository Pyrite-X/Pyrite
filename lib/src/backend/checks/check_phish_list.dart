import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

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
  // TODO: Implement fuzzy matching (highest premium tier).
  // TODO: include logic to just return failed result if disabled
  for (String name in phishingList) {
    bool usernameCheck = name.toLowerCase() == context.user.username.toLowerCase();
    bool nicknameCheck = name.toLowerCase() == context.user.nickname?.toLowerCase();
    if (usernameCheck || nicknameCheck) {
      matchString = name;
      break;
    }
  }

  return (matchString == null)
      ? CheckPhishResult(match: false)
      : CheckPhishResult(match: true, matchingString: matchString);
}
