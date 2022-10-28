CREATE MIGRATION m1ahoii26rzockhcrfu2ftypmtlhlfl5p744vlxqyultxw5r6bto4q
    ONTO m1rug7p6z3ygadvnwao3ib7k66r2735nlf5b4nzubwlyjk3pwtvhxq
{
  ALTER TYPE default::UserPremium {
      CREATE INDEX ON ((.userID, .transferringTo));
  };
};
