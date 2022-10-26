CREATE MIGRATION m1rug7p6z3ygadvnwao3ib7k66r2735nlf5b4nzubwlyjk3pwtvhxq
    ONTO m1ejefniqrta544zrkcar3lbs26kvaqh7ryg4pkwxy3kf543kizhwq
{
  ALTER TYPE default::Rule {
      CREATE CONSTRAINT std::exclusive ON ((.ruleID, .server));
  };
};
