module Game.Types.Response exposing (..)

import Game.Types.Types exposing (..)
import Game.Types.CreateOptions exposing (..)
import Game.Types.Request exposing (TopUserFilter, allTopUserFilter)
import Dict exposing (Dict)
import Json.Encode exposing (Value)

type alias Response =
    { info : ResponseInfo
    , result : Result
    }

type alias ResponseInfo =
    { class : String
    , method : String
    , request : Dict String Value
    }

type Result
    = RGet ResultGet
    | RConv ResultConv
    | RControl ResultControl
    | RInfo ResultInfo
    | RMulti ResultMulti
    | RError ErrorInfo

type ResultGet
    = GetUserStats UserStat
    | GetOwnUserStat UserStat
    | GetGroup Group
    | GetUser User
    | GetUserFromGroup (List User)
    | GetMyGroupUser (List User)
    | GetChatRoom Chat
    | GetChatRooms (List Chat)
    | GetChatEntrys (List ChatEntry)
    | GetVotes (List Vote)
    | GetConfig (Maybe String)
    | TopUser (List UserStat)
    | GetAllBansOfUser (List BanInfo)
    | GetNewestBans (List BanInfo)
    | GetOldestBans (List BanInfo)
    | GetUserSpokenBans (List BanInfo)
    | GetBansFromGroup (List BanInfo)

type ResultConv
    = LastOnline (List (Int, Int))
    | GetUpdatedGroup (Maybe Group)
    | GetChangedVotings (List Voting)
    | GetNewChatEntrys (List ChatEntry)
    | GetAllNewChatEntrys (List ChatEntry)
    | GetNewVotes (List Vote)

type ResultControl
    = CreateGroup Group
    | JoinGroup Group
    | ChangeLeader Group
    | StartNewGame Game
    | NextPhase Game
    | PostChat ChatEntry
    | StartVoting Voting
    | FinishVoting
    | Vote_ Vote
    | SetConfig String
    | LeaveGroup

type ResultInfo
    = InstalledGameTypes (List String)
    | CreateOptions_ CreateOptions
    | InstalledRoles (List String)
    | Rolesets (List String)

type ResultMulti
    = Multi (List Response)

type alias ErrorInfo =
    { key : String
    , info : String
    }