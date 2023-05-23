import 'package:pyrite/src/structures/rule.dart';
import 'package:test/test.dart';

import 'package:dotenv/dotenv.dart';
import 'package:pyrite/src/backend/database.dart' as db;
import 'package:pyrite/src/backend/cache.dart';
import 'package:pyrite/src/structures/action.dart';

void main() async {
  var env = DotEnv(includePlatformEnvironment: true);
  env.load(['bin/.env']);

  var cli = await db.DatabaseClient.create(initializing: true, uri: env["MONGO_URI"], databaseName: "test");

  /// Start the connection to Redis.
  // AppCache redis = await AppCache.init(
  //     host: env["REDIS_HOST"]!, port: int.parse(env["REDIS_PORT"]!), auth: env["REDIS_PASS"]);

  BigInt GUILD_ID = BigInt.from(440350951572897812);

  // Delete any guild data for the sample guild from the database - or else tests will complain.
  var guildCol = await cli.database.collection("guilds");
  await guildCol.deleteOne({"_id": GUILD_ID.toString()});

  group("database:", () {
    test("Create a new guild with default settings", () async {
      var result = await db.insertNewGuild(serverID: GUILD_ID);
      expect(result, {
        "_id": GUILD_ID,
        "onJoinEnabled": true,
        "fuzzyMatchPercent": 100,
        "rules": [
          {"type": 1, "enabled": true, "action": ActionEnum.kick.value}
        ]
      });
    });

    test("Create a duplicate guild entry", () async {
      expect(await db.insertNewGuild(serverID: GUILD_ID), null);
    });

    group("General Configurations:", () {
      test("Update the set log channel", () async {
        expect(await db.updateGuildConfig(serverID: GUILD_ID, logchannelID: BigInt.from(791160420555292682)),
            true);
      });

      test("Update the toggle for join event checking", () async {
        expect(await db.updateGuildConfig(serverID: GUILD_ID, onJoinEvent: false), true);
      });

      test("Update the matching threshold", () async {
        expect(await db.updateGuildConfig(serverID: GUILD_ID, fuzzyMatchPercent: 88), true);
      });

      test("Update the phishing list match action", () async {
        expect(
            await db.updateGuildConfig(
                serverID: GUILD_ID, phishingMatchAction: Action.fromString("kick,log")),
            true);
      });

      test("Update the toggle for phishing list matching", () async {
        expect(await db.updateGuildConfig(serverID: GUILD_ID, phishingMatchEnabled: false), true);
      });

      test("Update the excluded roles list", () async {
        expect(
            await db.updateGuildConfig(
                serverID: GUILD_ID, excludedRoles: [BigInt.from(12345), BigInt.from(678910)]),
            true);
      });

      test("Update a bunch of settings at once", () async {
        expect(
            await db.updateGuildConfig(
                serverID: GUILD_ID,
                logchannelID: BigInt.from(1),
                onJoinEvent: true,
                fuzzyMatchPercent: 99,
                phishingMatchAction: Action.fromString("log"),
                phishingMatchEnabled: true,
                excludedRoles: [BigInt.from(543210), BigInt.from(678910)]),
            true);
      });
    });

    group("Add Rules:", () {
      Rule exampleRule = Rule(
        ruleID: "aaaaaa",
        action: Action.fromString("log"),
        authorID: BigInt.from(123),
        pattern: "example",
      );
      Rule exampleRuleTwo = Rule(
        ruleID: "aaaaab",
        action: Action.fromString("log"),
        authorID: BigInt.from(123),
        pattern: "example",
      );
      Rule exampleRuleThree = Rule(
        ruleID: "aaaaac",
        action: Action.fromString("log"),
        authorID: BigInt.from(123),
        pattern: "example3",
      );
      Rule exampleRuleFour = Rule(
        ruleID: "aaaaac",
        action: Action.fromString("log"),
        authorID: BigInt.from(123),
        pattern: "example5",
      );

      test("Insert guild rule", () async {
        expect(await db.insertGuildRule(serverID: GUILD_ID, rule: exampleRule), true);
      });

      test("Insert duplicate (pattern) guild rule", () async {
        expect(await db.insertGuildRule(serverID: GUILD_ID, rule: exampleRuleTwo), false);
      });

      test("Insert another guild rule", () async {
        expect(await db.insertGuildRule(serverID: GUILD_ID, rule: exampleRuleThree), true);
      });

      test("Insert duplicate (ruleID) guild rule", () async {
        expect(await db.insertGuildRule(serverID: GUILD_ID, rule: exampleRuleFour), false);
      });
    });

    group("Remove Rules:", () {
      test("Remove rule that exists", () async {
        expect(await db.removeGuildRule(serverID: GUILD_ID, ruleID: "aaaaaa"), true);
      });

      test("Remove rule that does not exist", () async {
        expect(await db.removeGuildRule(serverID: GUILD_ID, ruleID: "b"), false);
      });

      test("Remove residual rule", () async {
        expect(await db.removeGuildRule(serverID: GUILD_ID, ruleID: "aaaaac"), true);
      });
    });
  });
}
