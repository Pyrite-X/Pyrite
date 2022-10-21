module default {
    type PhishingList {
        required property enabled -> bool {
            default := true;
        }
        
        required property action -> int16 {
            default := 1; #Kick
        };

        property fuzzyPercent -> int16 {
            default := 100;
            constraint min_value(75);
            constraint max_value(100);
        }

        property excludedRoles -> array<int64>;

        required link server -> Server {
            constraint exclusive;
        }
    }

    type Rule {
        required property ruleID -> str; # Hex string 
        required property authorID -> int64;
        
        required property pattern -> str {
            constraint max_len_value(64);
        }
        
        required property action -> int16 {
            default := 5 #Kick, log (1<<0 | 1<<2)
        }
        
        required property isRegex -> bool {
            default := false
        }

        property excludedRoles -> array<int64>;

        required link server -> Server;
    }

    type Server {
        required property serverID -> int64 {
            constraint exclusive;
        }
        
        required property joinAction -> int16 {
            default := 1 #Kick
        }
        
        required property onJoinEnabled -> bool {
            default := true;
        }

        property logchannelID -> int64;
    }

    type UserPremium {
        required property userID -> int64 {
            constraint exclusive;
        }
        required property code -> str;

        property tier -> str;
        property transferringTo -> int64;
    }
};
