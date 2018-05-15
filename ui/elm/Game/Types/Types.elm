module Game.Types.Types exposing (..)

-- global information about any user
type alias UserStat =
    -- The User Id
    { userId : Int 
    -- Unix Time of first game
    , firstGame : Maybe Int
    -- Unix Time of last game
    , lastGame : Maybe Int
    -- total count of games
    , gameCount : Int
    -- total count of wins
    , winningCount : Int
    -- total count of self moderated games
    , moderatedCount : Int
    -- Unix Time of last Online
    , lastOnline : Int
    -- AI Id (currently unused)
    , aiId : Maybe Int
    -- AI Name (currently unused)
    , aiNameKey : Maybe String
    -- AI Control Class (currently unused)
    , aiControlClass : Maybe String
    }

-- global information about a group
type alias Group =
    -- the unique id of this group
    { id : Int
    -- the creator defined name of this group
    , name : String
    -- Unix time of creation
    , created : Int
    -- Unix time of last started game
    , lastTime : Maybe Int
    -- UserStat Id of the creator
    , creator : Int
    -- UserStat Id of the current leader
    , leader : Int
    -- Game Object of the current  Game
    , currentGame : Maybe Game
    -- The key to enter this group
    , enterKey : String
    }

-- informations about a current game
type alias Game =
    -- the id of this game
    { id : Int
    -- the id of the refering group
    , mainGroupId : Int
    -- the Unix time when the game was started
    , started : Int
    -- the Unix time when this game was finished
    , finished : Maybe Int
    -- the indicator of the current phase
    -- night phases has the prefix 'n:' and day phases 'd:'
    , phase : String
    -- the counter of the current day. It starts always with 1
    , day : Int
    -- the indicator which ruleset should be used on the server
    -- to determine all actions
    , ruleset : String
    -- a list of all roles that won this game (only set if finished)
    , winningRoles : Maybe (List String)
    }

-- information about a user in a group
type alias User =
    -- the refering group id
    { group : Int
    -- the user id
    , user : Int
    -- the player object (only set if game starts and user is not a guest)
    , player : Maybe Player
    -- the stats with all the information about the user
    , stats : UserStat
    }

-- the player object in a game
type alias Player =
    -- the id of this player
    { id : Int
    -- the game id
    , game : Int
    -- the user id
    , user : Int
    -- determines if the user is currently alive
    , alive : Bool
    -- a bunch of roles that are currently visible to the current user
    , roles : List Role
    }

-- single information about a role
type alias Role = 
    -- the key to identify this role
    { roleKey : String
    -- the index of user with this role in this game
    , index : Int
    }

-- information about a single chat room
type alias Chat =
    -- the unique id of this room
    { id : Int
    -- the refering game id
    , game : Int
    -- the chat room key
    , chatRoom : String
    -- list of current votings in this room
    , voting : List Voting
    -- the current permission information about the current
    -- user in this chat
    , permission : Permission
    }

-- information about a voting to select an action
type alias Voting =
    -- the id of the chat where this voting is in
    { chat : Int
    -- the key of this voting, its only used to identify
    -- the voting in this chat
    , voteKey : String
    -- Unix time when this voting was created
    , created : Int
    -- Unix time when this voting was started 
    --(after that are votes possible)
    , voteStart : Maybe Int
    -- Unix time when this voting was finished
    -- (after that no more votes are possible)
    , voteEnd : Maybe Int
    -- List of player Ids who are allowed to vote
    , enabledUser : List Int
    -- List of player Ids who can be target of a vote
    , targetUser : List Int
    -- the result of this voting (can be Nothing)
    , result : Maybe Int
    }

-- information about the current permissions for the current user
-- for a specific chat
type alias Permission =
    -- the user is enabled to see this chat
    -- (this is always true, because all chats with false values are
    -- filtered on the server)
    { enable : Bool
    -- current user is enabled to write in this chat
    , write : Bool
    -- current user is visible to the others in this chat
    , visible : Bool
    -- a list of all other visible player ids who has access to this chat
    , player : List Int
    }

-- a single entry in a chat
type alias ChatEntry =
    -- the unique id for this entry
    { id : Int
    -- the chat id
    , chat : Int
    -- the user id (not player!)
    , user : Int
    -- the text that was written
    , text : String
    -- the Unix time when this chat was send
    , sendDate : Int
    }

-- a single vote in a voting
type alias Vote =
    -- the chat id where the voting is in
    -- combined with the voteKey it refers the voting itself
    { setting : Int
    -- refers with the setting the voting
    , voteKey : String
    -- the voter who gave the vote
    , voter : Int
    -- the target that was choosen by the voter
    , target : Int
    -- the Unix time when this vote was given
    , date : Int
    }