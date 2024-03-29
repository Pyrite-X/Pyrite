import 'dart:convert';

import 'package:alfred/alfred.dart';
import 'package:nyxx/nyxx.dart' show EmbedBuilder, EmbedFooterBuilder;
import 'package:onyx/onyx.dart';
import 'package:pyrite/src/discord_http.dart';
import 'package:unorm_dart/unorm_dart.dart' as unorm;

import '../../backend/storage.dart' as storage;
import '../../utilities/base_embeds.dart' as embeds;

const int BASE_NAME_LIMIT = 50;
const int BASE_ROLE_LIMIT = 10;

/// Interaction entrypoint
Future<void> whitelistLogic(Interaction interaction) async {
  var interactionData = interaction.data! as ApplicationCommandData;

  HttpRequest request = interaction.metadata["request"];

  ApplicationCommandOption subcommandGroup = interactionData.options![0];
  ApplicationCommandOption subcommand = subcommandGroup.options![0];

  String name = subcommand.name;
  switch (name) {
    case "names":
      await _names(interaction, request.response, subcommand);
      break;

    case "roles":
      await _roles(interaction, request.response, subcommand);
      break;

    default:
      print("Matching whitelist subcommand case was not found");
  }
}

/// Handler used for adding a name to the whitelist from a button press on an alert message.
Future<EmbedBuilder> addToWhitelistHandler(
    List<String> existingNames, List<String> newNames, BigInt guildID) async {
  EmbedBuilder embedResponse;

  if (newNames.isEmpty) {
    embedResponse = embeds.errorEmbed();
    embedResponse.description =
        "Your given input will result in nothing to add. Try again with a different list of names to add.";

    return embedResponse;
  }

  if (existingNames.length >= BASE_NAME_LIMIT) {
    int count = BASE_NAME_LIMIT - existingNames.length;
    embedResponse = embeds.warningEmbed();
    embedResponse.description = "You have too many names whitelisted. Please remove some before adding more. "
        "Pyrite has a limit of $BASE_NAME_LIMIT whitelisted names at a time, you can add `$count` more names.";

    return embedResponse;
  }

  if (existingNames.length + newNames.length >= BASE_NAME_LIMIT) {
    int count = BASE_NAME_LIMIT - existingNames.length;
    embedResponse = embeds.warningEmbed();
    embedResponse.description =
        "You will have too many names whitelisted. Please remove some before adding more. "
        "Pyrite has a limit of $BASE_NAME_LIMIT whitelisted names at a time, you can add `$count` more names.";

    return embedResponse;
  }

  newNames.forEach((element) {
    if (element.length >= 32) element = element.substring(0, 32);
  });
  bool success = await storage.addToWhitelist(guildID, names: newNames);

  if (success) {
    embedResponse = embeds.successEmbed();
    embedResponse.title = "Success!";
    embedResponse.description = "You changes to the whitelist have been saved successfully!\n\n"
        "You added these values to the name whitelist:\n> ${newNames.join(', ')}";
  } else {
    embedResponse = embeds.errorEmbed();
    embedResponse.title = "Error!";
    embedResponse.description = "Your changes to the whitelist were not saved. The name(s) you gave "
        "may already exist in the list.";
  }

  embedResponse.footer = EmbedFooterBuilder(
      text: "Names will be truncated to 32 characters as that is the limit imposed by Discord on users.");

  return embedResponse;
}

Future<void> _names(Interaction interaction, HttpResponse response, ApplicationCommandOption command) async {
  ApplicationCommandOption selection = command.options![0];

  String action = selection.value;

  bool addOrDelete = ["add", "delete"].contains(action);

  // User gave a selection but didn't give a list of names.
  if (command.options?.length == 1 && addOrDelete) {
    InteractionResponse botResponse = InteractionResponse(InteractionResponseType.message_response, {
      "content": "This command (</config whitelist names:1089072171072102481>), "
          "with the option to **add** or **remove** whitelisted names, needs a list of names!\n"
          "Make sure you provide a value with the `names` argument when running the command.",
      "flags": 1 << 6
    });

    await response.send(jsonEncode(botResponse));
    return;
  }

  // InteractionResponse deferResponse =
  //     InteractionResponse(InteractionResponseType.defer_message_response, null);
  // await response.send(jsonEncode(deferResponse));

  late ApplicationCommandOption nameInput;
  List<String> nameInputList = [];

  JsonData whitelistData = await storage.fetchGuildWhitelist(interaction.guild_id!);
  List<String> existingNameList = whitelistData["names"];

  if (addOrDelete) {
    nameInput = command.options!.last;
    // Split on comma, trim & normalize input, shove into a list.
    nameInputList = [
      for (String name in (nameInput.value as String).split(","))
        if (name.isNotEmpty) unorm.nfkc(name.trim())
    ];
  }

  late EmbedBuilder embedResponse;
  ActionRow actionRow = ActionRow();

  switch (action) {
    case "add":
      embedResponse = await addToWhitelistHandler(existingNameList, nameInputList, interaction.guild_id!);

      break;

    case "delete":
      if (nameInputList.isEmpty) {
        embedResponse = embeds.errorEmbed();
        embedResponse.description =
            "Your given input will result in nothing to remove. Try again with a different list of names to remove.";
        break;
      }

      List<String> nameList = whitelistData["names"];

      if (nameList.isEmpty) {
        embedResponse = embeds.warningEmbed();
        embedResponse.description = "You have no names whitelisted! You can't remove something from nothing.";
        break;
      }

      bool success = await storage.removeFromWhitelist(interaction.guild_id!, names: nameInputList);

      if (success) {
        embedResponse = embeds.successEmbed();
        embedResponse.title = "Success!";
        embedResponse.description = "You changes to the whitelist have been saved successfully!\n\n"
            "You removed these values from the name whitelist:\n> ${nameInput.value}";
      } else {
        embedResponse = embeds.errorEmbed();
        embedResponse.title = "Error!";
        embedResponse.description =
            "Your changes could not be saved. It is likely that the name given does not exist in the list.\n\n"
            "Here is the input you provided:\n> ${nameInput.value}";
      }

      break;

    case "clear":
      List<String> nameList = whitelistData["names"];

      if (nameList.isEmpty) {
        embedResponse = embeds.warningEmbed();
        embedResponse.description = "You have no names whitelisted! So therefore, there is nothing to clear!";
        break;
      }

      embedResponse = embeds.warningEmbed();
      embedResponse.title = "Are you sure you want to do this?";
      embedResponse.description = ">>> *Please confirm that you DO in fact want to "
          "clear your entire name whitelist.\n\n**THIS CANNOT BE UNDONE!***";

      actionRow = ActionRow();
      actionRow.addComponent(Button(
          style: ButtonStyle.danger,
          label: "No",
          custom_id: "whitelist:clear:names:no:${interaction.member!["user"]["id"]}"));
      actionRow.addComponent(Button(
          style: ButtonStyle.success,
          label: "Yes",
          custom_id: "whitelist:clear:names:yes:${interaction.member!["user"]["id"]}"));
      break;

    default:
      embedResponse = embeds.errorEmbed();
      embedResponse.description = "You somehow caused the bot to receive an interaction "
          "without a proper action in the `whitelist names` command. Bravo? Please report this.";
  }

  JsonData responseData = {
    "embeds": [
      {...embedResponse.build()}
    ],
    "components": [
      if (actionRow.components.isNotEmpty) {...actionRow.toJson()}
    ],
    "allowed_mentions": {"parse": []}
  };

  await response
      .send(jsonEncode(InteractionResponse(InteractionResponseType.message_response, responseData)));
}

Future<void> _roles(Interaction interaction, HttpResponse response, ApplicationCommandOption command) async {
  ApplicationCommandOption selection = command.options![0];

  String action = selection.value;
  String authorID = interaction.member!["user"]["id"];

  // InteractionResponse deferResponse =
  //     InteractionResponse(InteractionResponseType.defer_message_response, null);
  // await response.send(jsonEncode(deferResponse));

  JsonData whitelistData = await storage.fetchGuildWhitelist(interaction.guild_id!);

  DiscordHTTP discordHTTP = DiscordHTTP();
  late EmbedBuilder embedResponse;
  ActionRow actionRow = ActionRow();

  switch (action) {
    case "add":
      List<BigInt> roleList = whitelistData["roles"];
      int maxValues = BASE_ROLE_LIMIT - roleList.length;

      if (maxValues <= 0) {
        embedResponse = embeds.warningEmbed();
        embedResponse.description = "You have too many roles added to the whitelist!\n"
            "Try removing some so you have less than $BASE_ROLE_LIMIT roles on the whitelist at a time "
            "before adding more.";
        break;
      }

      embedResponse = embeds.infoEmbed();
      embedResponse.description = "Select which roles to add to the whitelist.";

      actionRow.addComponent(SelectMenu(
          custom_id: "whitelist:sel:roles:add:$authorID",
          type: ComponentType.role_select,
          min_values: 1,
          max_values: maxValues));

      break;

    case "delete":
      List<BigInt> roleList = whitelistData["roles"];
      if (roleList.isEmpty) {
        embedResponse = embeds.warningEmbed();
        embedResponse.description = "You have no roles whitelisted! You can't remove something from nothing.";
        break;
      }

      embedResponse = embeds.infoEmbed();
      embedResponse.description = "Select which roles to remove from the whitelist.";

      // Only show users database entries, this is bc deleted roles can't be picked via the discord role picker.
      var guildRoleReq = await discordHTTP.getGuildRoles(guildID: interaction.guild_id!);
      List<dynamic> guildRolesData = jsonDecode(guildRoleReq.body);

      Map<BigInt, String> roleNameList = {};
      for (JsonData item in guildRolesData) {
        BigInt id = BigInt.parse(item["id"].toString());
        String name = item["name"];

        roleNameList[id] = name;
      }

      SelectMenu deleteMenu = SelectMenu(
        custom_id: "whitelist:sel:roles:delete:$authorID",
        type: ComponentType.string_select,
        min_values: 1,
      );
      for (BigInt roleID in roleList) {
        String name = "Invalid Role ($roleID)";
        if (roleNameList.containsKey(roleID)) {
          name = "${roleNameList[roleID]} ($roleID)";
          // Cap to 100 characters bc that's the discord limit
          name = name.substring(0, (name.length > 99) ? 99 : name.length - 1);
        }
        deleteMenu.addOption(SelectMenuOption(label: name, value: roleID.toString()));
      }

      deleteMenu.min_values = 0;
      deleteMenu.max_values = deleteMenu.options.length;
      actionRow.addComponent(deleteMenu);

      break;

    case "clear":
      List<BigInt> roleList = whitelistData["roles"];
      embedResponse = embeds.warningEmbed();

      if (roleList.isEmpty) {
        embedResponse.description = "You have no roles whitelisted! So therefore, there is nothing to clear!";
        break;
      }

      embedResponse = embeds.warningEmbed();
      embedResponse.title = "Are you sure you want to do this?";
      embedResponse.description = ">>> *Please confirm that you DO in fact want to "
          "clear your entire role whitelist.\n\n**THIS CANNOT BE UNDONE!***";

      actionRow = ActionRow();
      actionRow.addComponent(
          Button(style: ButtonStyle.danger, label: "No", custom_id: "whitelist:clear:roles:no:$authorID"));
      actionRow.addComponent(
          Button(style: ButtonStyle.success, label: "Yes", custom_id: "whitelist:clear:roles:yes:$authorID"));
      break;

    default:
      embedResponse = embeds.errorEmbed();
      embedResponse.description = "You somehow caused the bot to receive an interaction "
          "without a proper action in the `whitelist roles` command. Bravo? Please report this.";
  }

  JsonData responseData = {
    "embeds": [
      {...embedResponse.build()}
    ],
    "components": [
      if (actionRow.components.isNotEmpty) {...actionRow.toJson()}
    ],
    "allowed_mentions": {"parse": []}
  };

  await response
      .send(jsonEncode(InteractionResponse(InteractionResponseType.message_response, responseData)));
}
