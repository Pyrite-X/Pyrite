import 'dart:convert';

import 'package:alfred/alfred.dart';
import 'package:nyxx/nyxx.dart' show EmbedBuilder, EmbedFooterBuilder;
import 'package:onyx/onyx.dart';

import '../../discord_http.dart';
import '../../structures/action.dart';
import '../../structures/rule.dart';
import '../../backend/storage.dart' as storage;
import '../../utilities/base_embeds.dart' as embeds;

const MAX_PER_PAGE = 4;
const PREV_PAGE_ID = "rl:prev";
const NEXT_PAGE_ID = "rl:next";

Future<void> rulesCmd(Interaction interaction) async {
  var interactionData = interaction.data! as ApplicationCommandData;

  ApplicationCommandOption subcommand = interactionData.options![0];
  String optionName = subcommand.name;

  if (optionName == "view") {
    await viewRules(interaction);
  } else if (optionName == "add") {
    await addRule(interaction, subcommand.options!);
  } else if (optionName == "delete") {
    await deleteRule(interaction, subcommand.options![0].value.toString());
  }
}

Future<void> viewRules(Interaction interaction) async {
  HttpRequest request = interaction.metadata["request"];

  List<Rule> result = await storage.fetchGuildRules(interaction.guild_id!);

  late EmbedBuilder embedBuilder;
  StringBuffer description = StringBuffer();

  if (result.isEmpty) {
    embedBuilder = embeds.warningEmbed();
    description.writeln("You have no custom rules configured!");
    description.writeln("Get started with </rules add:1022784407704191009>!");
  } else if (result.length <= MAX_PER_PAGE) {
    embedBuilder = embeds.infoEmbed();
    embedBuilder.title = "Your guild's custom rules:";
    result.forEach((element) => description.writeln(element.toString()));
  } else {
    await _paginatedRuleView(interaction, result);
    return;
  }

  embedBuilder.footer = EmbedFooterBuilder(text: "Guild ID: ${interaction.guild_id.toString()}");
  embedBuilder.description = description.toString();

  await request.response.send(jsonEncode(InteractionResponse(InteractionResponseType.message_response, {
    "embeds": [
      {...embedBuilder.build()}
    ]
  })));
}

Future<void> _paginatedRuleView(Interaction interaction, List<Rule> ruleList) async {
  EmbedBuilder embedBuilder = embeds.infoEmbed();
  embedBuilder.title = "Your guild's custom rules:";

  int maxPages = (ruleList.length / MAX_PER_PAGE).ceil();
  int currentPage = 0;

  List<String> pages = [];

  StringBuffer sb = StringBuffer();
  for (int i = 0; i < maxPages; i++) {
    int x = i * MAX_PER_PAGE;
    int y = (x + MAX_PER_PAGE >= ruleList.length) ? ruleList.length : x + MAX_PER_PAGE;

    Iterable<Rule> ruleRange = ruleList.getRange(x, y);
    ruleRange.forEach((element) => sb.writeln(element.toString()));

    pages.insert(i, sb.toString());
    sb.clear();
  }

  embedBuilder.description = pages[0];
  EmbedFooterBuilder footerBuilder = EmbedFooterBuilder(text: "Page ${currentPage + 1}/${pages.length}");

  embedBuilder.footer = footerBuilder;

  ActionRow buttonRow = ActionRow();
  buttonRow
      .addComponent(Button(style: ButtonStyle.primary, label: "<", disabled: true, custom_id: PREV_PAGE_ID));
  buttonRow
      .addComponent(Button(style: ButtonStyle.primary, label: ">", disabled: false, custom_id: NEXT_PAGE_ID));

  JsonData responseData = {
    "embeds": [
      {...embedBuilder.build()}
    ],
    "components": [
      {...buttonRow.toJson()}
    ]
  };
  InteractionResponse response = InteractionResponse(InteractionResponseType.message_response, responseData);
  await (interaction.metadata["request"] as HttpRequest).response.send(jsonEncode(response));

  DiscordHTTP discordHTTP = DiscordHTTP();

  var thisStream = OnyxStreams.componentStream.where((event) =>
      event.guild_id == interaction.guild_id &&
      event.channel_id == interaction.channel_id &&
      event.member!["user"]["id"] == interaction.member!["user"]["id"]);

  thisStream = thisStream.timeout(Duration(minutes: 1), onTimeout: (sink) async {
    buttonRow.components.forEach((element) {
      (element as Button).disabled = true;
    });

    discordHTTP.editInitialInteractionResponse(interactionToken: interaction.token, payload: {
      "embeds": [
        {...embedBuilder.build()}
      ],
      "components": [
        {...buttonRow.toJson()}
      ]
    });
    sink.close();
    return;
  });

  thisStream.listen((event) async {
    MessageComponentData data = event.data! as MessageComponentData;
    HttpRequest request = event.metadata["request"];
    InteractionResponse response = InteractionResponse(InteractionResponseType.update_message, {});

    switch (data.custom_id) {
      case (PREV_PAGE_ID):
        {
          currentPage = (currentPage - 1 < 0) ? 0 : currentPage - 1;
          if (currentPage == 0) {
            (buttonRow.components[0] as Button).disabled = true;
            (buttonRow.components[1] as Button).disabled = false;
          } else {
            (buttonRow.components[0] as Button).disabled = false;
            (buttonRow.components[1] as Button).disabled = false;
          }

          embedBuilder.description = pages[currentPage];
          footerBuilder.text = "Page ${currentPage + 1}/${pages.length}";
          response.data = {
            "embeds": [
              {...embedBuilder.build()}
            ],
            "components": [
              {...buttonRow.toJson()}
            ]
          };

          await request.response.send(jsonEncode(response));
        }
        break;

      case (NEXT_PAGE_ID):
        {
          currentPage = (currentPage + 1 >= maxPages) ? maxPages : currentPage + 1;
          if (currentPage + 1 == maxPages) {
            (buttonRow.components[0] as Button).disabled = false;
            (buttonRow.components[1] as Button).disabled = true;
          } else {
            (buttonRow.components[0] as Button).disabled = false;
            (buttonRow.components[1] as Button).disabled = false;
          }

          embedBuilder.description = pages[currentPage];
          footerBuilder.text = "Page ${currentPage + 1}/${pages.length}";
          response.data = {
            "embeds": [
              {...embedBuilder.build()}
            ],
            "components": [
              {...buttonRow.toJson()}
            ]
          };

          await request.response.send(jsonEncode(response));
        }
        break;

      default:
        break;
    }
  });
}

Future<void> addRule(Interaction interaction, List<ApplicationCommandOption> options) async {
  HttpRequest request = interaction.metadata["request"];

  late EmbedBuilder embedBuilder;

  RuleBuilder ruleBuilder = RuleBuilder();
  ruleBuilder.generateRuleID();

  StringBuffer descBuffer = StringBuffer();

  /// No alternative since user object will be null since these commands don't work in DMs.
  /// Goes from member object > nested user object > id of said user object.
  if (interaction.member != null) {
    if (interaction.member!["user"] != null) {
      String userID = interaction.member!["user"]["id"];
      ruleBuilder.setAuthorID(BigInt.parse(userID));
    }
  }

  options.forEach((element) {
    if (element.name == "pattern") {
      ruleBuilder.setPattern(element.value);
    } else if (element.name == "action") {
      Action action = Action.fromString(element.value);
      ruleBuilder.setAction(action);
    } else if (element.name == "regex") {
      ruleBuilder.setRegexFlag(element.value);
    }
  });

  Rule builtRule = ruleBuilder.build();
  descBuffer.writeln(builtRule.toString());

  JsonData ruleStatus = await storage.canAddRule(interaction.guild_id!, rule: builtRule);
  bool canAdd = ruleStatus["flag"];
  String flagReason = ruleStatus["reason"];
  if (!canAdd) {
    embedBuilder = embeds.errorEmbed();
    embedBuilder.description = "$flagReason Try deleting some rules first!";
    embedBuilder.footer = EmbedFooterBuilder(text: "Guild ID: ${interaction.guild_id.toString()}");

    var response = InteractionResponse(InteractionResponseType.message_response, {
      "embeds": [
        {...embedBuilder.build()}
      ]
    });
    await request.response.send(jsonEncode(response));

    return;
  }

  bool success = await storage.insertGuildRule(serverID: interaction.guild_id!, rule: builtRule);
  if (!success) {
    embedBuilder = embeds.warningEmbed();
    embedBuilder.description =
        "Your rule could not be created. This is likely because the pattern `${builtRule.pattern}`"
        " matches the pattern of an already existing rule.";
  } else {
    embedBuilder = embeds.successEmbed();
    embedBuilder.title = "New rule created:";
    embedBuilder.description = descBuffer.toString();
  }

  embedBuilder.footer = EmbedFooterBuilder(text: "Guild ID: ${interaction.guild_id.toString()}");

  var response = InteractionResponse(InteractionResponseType.message_response, {
    "embeds": [
      {...embedBuilder.build()}
    ]
  });
  await request.response.send(jsonEncode(response));
}

Future<void> deleteRule(Interaction interaction, String ruleID) async {
  HttpRequest request = interaction.metadata["request"];

  late EmbedBuilder embedBuilder;

  var result = await storage.removeGuildRule(serverID: interaction.guild_id!, ruleID: ruleID);

  if (!result) {
    embedBuilder = embeds.errorEmbed();
    embedBuilder.description = "Rule **$ruleID** could not be found.";
  } else {
    embedBuilder = embeds.successEmbed();
    embedBuilder.description = "Rule **$ruleID** was deleted.";
  }
  embedBuilder.footer = EmbedFooterBuilder(text: "Guild ID: ${interaction.guild_id.toString()}");

  var response = InteractionResponse(InteractionResponseType.message_response, {
    "embeds": [
      {...embedBuilder.build()}
    ]
  });
  await request.response.send(jsonEncode(response));
}
