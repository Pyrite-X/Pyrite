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
  //TODO: Implement fuzzy matching (highest premium tier).
  for (String name in phishingList) {
    if (name == context.user.username) {
      matchString = name;
      break;
    } else if (context.user.nickname != null && name == context.user.nickname) {
      matchString = name;
      break;
    }
  }

  if (matchString == null) {
    return CheckPhishResult(match: false);
  } else {
    return CheckPhishResult(match: true, matchingString: matchString);
  }
}
