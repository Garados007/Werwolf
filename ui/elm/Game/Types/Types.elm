module Game.Types.Types exposing (..)

import Time exposing (Posix)

type UserId = UserId Int 

type GroupId = GroupId Int

type GameId = GameId Int

type PlayerId = PlayerId Int

type ChatId = ChatId Int

type ChatEntryId = ChatEntryId Int

type VoteKey = VoteKey String

-- global information about any user
type alias UserStat =
    -- The User Id
    { userId : UserId
    -- The User name
    , name : String
    -- The hash sum for the gravatar image
    , gravatar: String
    -- Unix Time of first game
    , firstGame : Maybe Posix
    -- Unix Time of last game
    , lastGame : Maybe Posix
    -- total count of games
    , gameCount : Int
    -- total count of wins
    , winningCount : Int
    -- total count of self moderated games
    , moderatedCount : Int
    -- Unix Time of last Online
    , lastOnline : Posix
    -- AI Id (currently unused)
    , aiId : Maybe Int
    -- AI Name (currently unused)
    , aiNameKey : Maybe String
    -- AI Control Class (currently unused)
    , aiControlClass : Maybe String
    -- total count of all bans
    , totalBanCount : Int
    -- total count of complete banned days
    , totalBanDays : Int
    -- count of all active perma bans
    , permaBanCount : Int
    -- count of all spoken bans
    , spokenBanCount : Int
    }

-- global information about a group
type alias Group =
    -- the unique id of this group
    { id : GroupId
    -- the creator defined name of this group
    , name : String
    -- Unix time of creation
    , created : Posix
    -- Unix time of last started game
    , lastTime : Maybe Posix
    -- UserStat Id of the creator
    , creator : UserId
    -- UserStat Id of the current leader
    , leader : UserId
    -- Game Object of the current  Game
    , currentGame : Maybe Game
    -- The key to enter this group
    , enterKey : String
    }

-- informations about a current game
type alias Game =
    -- the id of this game
    { id : GameId
    -- the id of the refering group
    , mainGroupId : GroupId
    -- the Unix time when the game was started
    , started : Posix
    -- the Unix time when this game was finished
    , finished : Maybe Posix
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
    { group : GroupId
    -- the user id
    , user : UserId
    -- the player object (only set if game starts and user is not a guest)
    , player : Maybe Player
    -- the stats with all the information about the user
    , stats : UserStat
    }

-- the player object in a game
type alias Player =
    -- the id of this player
    { id : PlayerId
    -- the game id
    , game : GameId
    -- the user id
    , user : UserId
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
    { id : ChatId
    -- the refering game id
    , game : GameId
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
    { chat : ChatId
    -- the key of this voting, its only used to identify
    -- the voting in this chat
    , voteKey : String
    -- Unix time when this voting was created
    , created : Posix
    -- Unix time when this voting was started 
    --(after that are votes possible)
    , voteStart : Maybe Posix
    -- Unix time when this voting was finished
    -- (after that no more votes are possible)
    , voteEnd : Maybe Posix
    -- List of player Ids who are allowed to vote
    , enabledUser : List PlayerId
    -- List of player Ids who can be target of a vote
    , targetUser : List PlayerId
    -- the result of this voting (can be Nothing)
    , result : Maybe PlayerId
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
    , player : List PlayerId
    }

-- a single entry in a chat
type alias ChatEntry =
    -- the unique id for this entry
    { id : ChatEntryId
    -- the chat id
    , chat : ChatId
    -- the user id
    , user : UserId
    -- the text that was written
    , text : String
    -- the Unix time when this chat was send
    , sendDate : Posix
    }

-- a single vote in a voting
type alias Vote =
    -- the chat id where the voting is in
    -- combined with the voteKey it refers the voting itself
    { setting : ChatId
    -- refers with the setting the voting
    , voteKey : VoteKey
    -- the voter who gave the vote
    , voter : PlayerId
    -- the target that was choosen by the voter
    , target : PlayerId
    -- the Unix time when this vote was given
    , date : Posix
    }

-- contains information about a single ban
type alias BanInfo =
    -- the user that was banned
    { user : UserId
    -- the spoker who has banned the user
    , spoker : UserId
    -- the group in which the user is banned
    , group : GroupId
    -- the date when this ban was created and starts
    , startDate : Posix
    -- the end date of this ban or Nothing if its infinitive
    , endDate : Maybe Posix
    -- the reason why the user was banned for
    , comment : String
    }