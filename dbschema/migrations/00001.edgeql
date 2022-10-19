CREATE MIGRATION m1qjpakhfzc6ekvpqgixs43plioaj4x5yjzy2l7tezu7cjvlg5q52q
    ONTO initial
{
  CREATE TYPE default::Server {
      CREATE REQUIRED PROPERTY joinAction -> std::int16 {
          SET default := 1;
      };
      CREATE PROPERTY logchannelID -> std::int64;
      CREATE REQUIRED PROPERTY onJoinEnabled -> std::bool {
          SET default := true;
      };
      CREATE REQUIRED PROPERTY serverID -> std::int64;
  };
  CREATE TYPE default::PhishingList {
      CREATE PROPERTY excludedRoles -> array<std::int64>;
      CREATE REQUIRED LINK server -> default::Server {
          CREATE CONSTRAINT std::exclusive;
      };
      CREATE REQUIRED PROPERTY action -> std::int16 {
          SET default := 1;
      };
      CREATE REQUIRED PROPERTY enabled -> std::bool {
          SET default := true;
      };
      CREATE PROPERTY fuzzyPercent -> std::int16 {
          SET default := 100;
          CREATE CONSTRAINT std::max_value(100);
          CREATE CONSTRAINT std::min_value(75);
      };
  };
  CREATE TYPE default::Rule {
      CREATE PROPERTY excludedRoles -> array<std::int64>;
      CREATE REQUIRED LINK server -> default::Server;
      CREATE REQUIRED PROPERTY action -> std::int16 {
          SET default := 5;
      };
      CREATE REQUIRED PROPERTY authorID -> std::int64;
      CREATE REQUIRED PROPERTY isRegex -> std::bool {
          SET default := false;
      };
      CREATE REQUIRED PROPERTY pattern -> std::str {
          CREATE CONSTRAINT std::max_len_value(64);
      };
      CREATE REQUIRED PROPERTY ruleID -> std::str;
  };
  CREATE TYPE default::UserPremium {
      CREATE REQUIRED PROPERTY code -> std::str;
      CREATE PROPERTY tier -> std::str;
      CREATE PROPERTY transferringTo -> std::int64;
      CREATE REQUIRED PROPERTY userID -> std::int64;
  };
};
