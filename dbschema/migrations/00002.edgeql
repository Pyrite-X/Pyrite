CREATE MIGRATION m1ejefniqrta544zrkcar3lbs26kvaqh7ryg4pkwxy3kf543kizhwq
    ONTO m1qjpakhfzc6ekvpqgixs43plioaj4x5yjzy2l7tezu7cjvlg5q52q
{
  ALTER TYPE default::Server {
      ALTER PROPERTY serverID {
          CREATE CONSTRAINT std::exclusive;
      };
  };
  ALTER TYPE default::UserPremium {
      ALTER PROPERTY userID {
          CREATE CONSTRAINT std::exclusive;
      };
  };
};
