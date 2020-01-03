module Dashboard.Environment exposing (..)

import Set exposing (Set)
import Dict exposing (Dict)

type alias Environment =
    { keys : EnvironmentKeys
    , moduleName : String
    , game : GameSetup 
    , roles : Dict String RoleSetup
    }

type alias EnvironmentKeys =
    { chatKeys : Set String 
    , phaseKeys : Set String 
    , roleKeys : Set String 
    , votingKeys : Set String
    }

type alias GameSetup =
    -- phase key
    { startPhase : String 
    , chatExceptions : Set String 
    -- boundled rolesets for startup: key: name, value: set of roles
    , rolesets : Dict String (Set String)
    -- fractions for winning: key: name, value: set of roles
    , fractions : Dict String (Set String)
    }

type alias RoleSetup =
    { key : String
    , type_ : String
    , comment : String
    -- definiert  alle Rollen, die diese Rolle default sehen kann
    , initCanView : Set String
    -- set if this phases will be required, code will overwrite this value
    , reqPhases : Set String  --check
    , leader : Bool 
    , canStartNewRound : Bool 
    , canStartVotings : Bool 
    , canStopVotings : Bool 
    -- default permissions for a room, this code will executed automaticly 
    -- in onStartRound
    -- 1st key: Phase, 2nd key: chat
    , permissions : Dict String (Dict String PermissionInfo) --check
    -- win together with one of these rolese submited
    -- code will overwrite these settings
    -- only required if fractions are not used
    , winTogether : Set String --check
    -- key: chat key, value: set of votings 
    , canVote : Dict String (Set String) --check
    }

type alias PermissionInfo =
    { read : Bool
    , write : Bool
    , visible : Bool 
    }

empty : Environment
empty =
    { keys =
        { chatKeys = Set.empty
        , phaseKeys = Set.empty
        , roleKeys = Set.empty
        , votingKeys = Set.empty
        }
    , moduleName = "New Module"
    , game =
        { startPhase = ""
        , chatExceptions = Set.empty 
        , rolesets = Dict.empty
        , fractions = Dict.empty
        }
    , roles = Dict.empty
    }

emptyRole : String -> RoleSetup
emptyRole key =
    { key = key 
    , type_ = "user"
    , comment = ""
    , initCanView = Set.singleton key
    , reqPhases = Set.empty
    , leader = False
    , canStartNewRound = False
    , canStartVotings = False
    , canStopVotings = False
    , permissions = Dict.empty 
    , winTogether = Set.empty
    , canVote = Dict.empty 
    }

test : Environment
test =
    { keys =
        { chatKeys = Set.fromList [ "chat1", "chat2", "chat3" ]
        , phaseKeys = Set.fromList [ "phase1", "phase2", "phase3" ]
        , roleKeys = Set.fromList [ "role1", "role2", "role3" ]
        , votingKeys = Set.fromList [ "voting1", "voting2", "voting3" ]
        }
    , moduleName = "Test Module"
    , game =
        { startPhase = "phase1"
        , chatExceptions = Set.singleton "chat1"
        , rolesets = Dict.singleton "role1" <| Set.singleton "role1"
        , fractions = Dict.fromList
            [ Tuple.pair "frac1" <| Set.singleton "role1"
            , Tuple.pair "frac2" <| Set.fromList
                [ "role2", "role3" ]
            ]
        }
    , roles = Dict.fromList
        [ Tuple.pair "role1"
            { key = "role1"
            , type_ = "user"
            , comment = ""
            , initCanView = Set.fromList [ "role1", "role3" ]
            , reqPhases = Set.fromList [ "phase2" ]
            , leader = False
            , canStartNewRound = False
            , canStartVotings = True
            , canStopVotings = False
            , permissions = Dict.singleton "phase1"
                <| Dict.singleton "chat1"
                <| PermissionInfo True True True
            , winTogether = Set.empty
            , canVote = Dict.singleton "chat2" <| Set.singleton "voting2"
            }
        , Tuple.pair "role2" <| emptyRole "role2"
        , Tuple.pair "role3" <| emptyRole "role3"
        ]
    }