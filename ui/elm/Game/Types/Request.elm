module Game.Types.Request exposing
    ( GroupVersion, NewGameConfig
    , TopUserFilter (..)
    , Response (..)
    , ResponseGet (..)
    , ResponseConv (..)
    , ResponseControl (..)
    , ResponseInfo (..)
    , ResponseMulti (..)
    , EncodedRequest
    , encodeJson
    , encodeRequest
    , allTopUserFilter
    )

import Json.Encode exposing (Value, object, string, int, list, encode)
import List exposing (map)
import Dict exposing (Dict)

import Game.Types.Types exposing (..)
import Time exposing (Posix)

type alias GroupVersion =
    { group : GroupId
    , lastChange : Int
    , leader : Int
    , phaseDay : Maybe (String, Int)
    }

type alias NewGameConfig =
    { group : GroupId
    , roles : Dict String Int
    , ruleset : String
    , config : Value
    }

type TopUserFilter
    = TFMostGames
    | TFMostWinGames
    | TFMostModGames
    | TFTopWinner
    | TFTopMod
    | TFMostBanned
    | TFLongestBanned
    | TFMostPermaBanned

type Response
    = RespGet ResponseGet
    | RespConv ResponseConv
    | RespControl ResponseControl
    | RespInfo ResponseInfo
    | RespMulti ResponseMulti

type ResponseGet
    = GetUserStats UserId
    | GetOwnUserStat
    | GetGroup GroupId
    | GetUser GroupId UserId
    | GetUserFromGroup GroupId
    | GetMyGroupUser
    | GetChatRoom ChatId
    | GetChatRooms GameId
    | GetChatEntrys ChatId
    | GetVotes ChatId VoteKey
    | GetConfig
    | TopUser TopUserFilter
    | GetAllBansOfUser UserId
    | GetNewestBans
    | GetOldestBans
    | GetUserSpokenBans UserId
    | GetBansFromGroup GroupId

type ResponseConv
    = LastOnline GroupId
    | GetUpdatedGroup GroupVersion
    | GetChangedVotings GameId Posix --LastChange
    | GetNewChatEntrys ChatId Posix --After
    | GetAllNewChatEntrys GameId ChatEntryId --AfterId
    | GetNewVotes ChatId VoteKey Posix --LastChange
    
type ResponseControl
    = CreateGroup String --name
    | JoinGroup String --key
    | ChangeLeader GroupId UserId
    | StartNewGame NewGameConfig
    | NextPhase GameId
    | PostChat ChatId String
    | StartVoting ChatId VoteKey
    | FinishVoting ChatId VoteKey
    | Vote ChatId VoteKey PlayerId
    | SetConfig String
    | LeaveGroup GroupId
    | BanUser UserId GroupId Posix String
    | KickUser UserId GroupId
    | RevokeBan UserId GroupId

type ResponseInfo
    = InstalledGameTypes
    | CreateOptions String
    | Rolesets String

type ResponseMulti
    = Multi (List Response)

type alias EncodedRequestInternal =
    { class : String
    , method : String
    , vars : List (String, EncodedValue)
    }

type alias EncodedRequest =
    { class : String
    , method : String
    , vars : List (String, String)
    }

type EncodedValue
    = EInt Int
    | EString String

allTopUserFilter : Dict String TopUserFilter
allTopUserFilter = Dict.fromList
    [ ( "mostGames", TFMostGames )
    , ( "mostWinGames", TFMostWinGames )
    , ( "mostModGames", TFMostModGames )
    , ( "topWinner", TFTopWinner )
    , ( "topMod", TFTopMod )
    , ( "mostBanned", TFMostBanned )
    , ( "longestBanned", TFLongestBanned )
    , ( "mostPermaBanned", TFMostPermaBanned )
    ]

ePosix : Posix -> EncodedValue
ePosix posix = EInt <| Time.posixToMillis posix // 1000

encodeRequestInternal : Response -> EncodedRequestInternal
encodeRequestInternal response =
    case response of
        RespGet resp ->
            case resp of
                GetUserStats (UserId userId) ->
                    EncodedRequestInternal "get" "getUserStats"
                        [ ("user", EInt userId)
                        ]
                GetOwnUserStat ->
                    EncodedRequestInternal "get" "getOwnUserStat"
                        []
                GetGroup (GroupId groupId) ->
                    EncodedRequestInternal "get" "getGroup"
                        [ ("group", EInt groupId)
                        ]
                GetUser (GroupId groupId) (UserId userId) ->
                    EncodedRequestInternal "get" "getUser"
                        [ ("group", EInt groupId)
                        , ("user", EInt userId)
                        ]
                GetUserFromGroup (GroupId groupId) ->
                    EncodedRequestInternal "get" "getUserFromGroup"
                        [ ("group", EInt groupId)
                        ]
                GetMyGroupUser ->
                    EncodedRequestInternal "get" "getMyGroupUser"
                        []
                GetChatRoom (ChatId chatId) ->
                    EncodedRequestInternal "get" "getChatRoom"
                        [ ("chat", EInt chatId)
                        ]
                GetChatRooms (GameId gameId) ->
                    EncodedRequestInternal "get" "getChatRooms"
                        [ ("game", EInt gameId)
                        ]
                GetChatEntrys (ChatId chatId) ->
                    EncodedRequestInternal "get" "getChatEntrys"
                        [ ("chat", EInt chatId)
                        ]
                GetVotes (ChatId chatId) (VoteKey voteKey) ->
                    EncodedRequestInternal "get" "getVotes"
                        [ ("chat", EInt chatId)
                        , ("voteKey", EString voteKey)
                        ]
                GetConfig ->
                    EncodedRequestInternal "get" "getConfig"
                        []
                TopUser filter ->
                    EncodedRequestInternal "get" "topUser"
                        [ ("filter", EString <|
                            Maybe.withDefault "" <| 
                            List.head <|
                            List.filterMap
                            (\(k,v) -> if v == filter then Just k else Nothing)
                            <| Dict.toList allTopUserFilter
                        )
                        ]
                GetAllBansOfUser (UserId user) ->
                    EncodedRequestInternal "get" "getAllBansOfUser"
                        [ ("user", EInt user)
                        ]
                GetNewestBans ->
                    EncodedRequestInternal "get" "getNewestBans"
                        []
                GetOldestBans ->
                    EncodedRequestInternal "get" "getOldestBans"
                        []
                GetUserSpokenBans (UserId user) ->
                    EncodedRequestInternal "get" "getUserSpokenBans"
                        [ ("user", EInt user)
                        ]
                GetBansFromGroup (GroupId group) ->
                    EncodedRequestInternal "get" "getBansFromGroup"
                        [ ("group", EInt group)
                        ]
        RespConv resp ->
            case resp of
                LastOnline (GroupId groupId) ->
                    EncodedRequestInternal "conv" "lastOnline"
                        [ ("group", EInt groupId)
                        ]
                GetUpdatedGroup gv ->
                    EncodedRequestInternal "conv" "getUpdatedGroup"
                        (
                            [ ("group", gv.group |> \(GroupId id) -> EInt id)
                            , ("lastChange", EInt gv.lastChange)
                            , ("leader", EInt gv.leader)
                            ]
                        ++ (case gv.phaseDay of
                            Just (p,d) ->
                                [ ("phase", EString p)
                                , ("day", EInt d)
                                ]
                            Nothing -> []
                        ))
                GetChangedVotings (GameId gameId) lastChange ->
                    EncodedRequestInternal "conv" "getChangedVotings"
                        [ ("game", EInt gameId)
                        , ("lastChange", ePosix lastChange)
                        ]
                GetNewChatEntrys (ChatId chatId) after ->
                    EncodedRequestInternal "conv" "getNewChatEntrys"
                        [ ("chat", EInt chatId)
                        , ("after", ePosix after)
                        ]
                GetAllNewChatEntrys (GameId gameId) (ChatEntryId after) ->
                    EncodedRequestInternal "conv" "getAllNewChatEntrys"
                        [ ("game", EInt gameId)
                        , ("after", EInt after)
                        ]
                GetNewVotes (ChatId chatId) (VoteKey voteKey) lastChange ->
                    EncodedRequestInternal "conv" "getNewVotes"
                        [ ("chat", EInt chatId)
                        , ("voteKey", EString voteKey)
                        , ("lastChange", ePosix lastChange)
                        ]
        RespControl resp ->
            case resp of
                CreateGroup name ->
                    EncodedRequestInternal "control" "createGroup"
                        [ ("name", EString name)
                        ]
                JoinGroup key ->
                    EncodedRequestInternal "control" "joinGroup"
                        [ ("key", EString key)
                        ]
                ChangeLeader (GroupId groupId) (UserId userId) ->
                    EncodedRequestInternal "control" "changeLeader"
                        [ ("group", EInt groupId)
                        , ("leader", EInt userId)
                        ]
                StartNewGame ng ->
                    EncodedRequestInternal "control" "startNewGame"
                        [ ("group", ng.group |> \(GroupId id) -> EInt id)
                        , ("roles", EString <| encode 0 <| object <| 
                            List.map (\(k,v) -> (k,int v)) <|
                            Dict.toList ng.roles)
                        , ("ruleset", EString ng.ruleset)
                        , ("config", EString <| encode 0 ng.config)
                        ]
                NextPhase (GameId gameId) ->
                    EncodedRequestInternal "control" "nextPhase"
                        [ ("game", EInt gameId)
                        ]
                PostChat (ChatId chatId) chat ->
                    EncodedRequestInternal "control" "postChat"
                        [ ("chat", EInt chatId)
                        , ("text", EString chat)
                        ]
                StartVoting (ChatId chatId) (VoteKey voteKey) ->
                    EncodedRequestInternal "control" "startVoting"
                        [ ("chat", EInt chatId)
                        , ("voteKey", EString voteKey)
                        ]
                FinishVoting (ChatId chatId) (VoteKey voteKey) ->
                    EncodedRequestInternal "control" "finishVoting"
                        [ ("chat", EInt chatId)
                        , ("voteKey", EString voteKey)
                        ]
                Vote (ChatId chatId) (VoteKey voteKey) (PlayerId playerId) ->
                    EncodedRequestInternal "control" "vote"
                        [ ("chat", EInt chatId)
                        , ("voteKey", EString voteKey)
                        , ("target", EInt playerId)
                        ]
                SetConfig config ->
                    EncodedRequestInternal "control" "setConfig"
                        [ ("config", EString config)
                        ]
                LeaveGroup (GroupId group) ->
                    EncodedRequestInternal "control" "leaveGroup"
                        [ ("group", EInt group)
                        ]
                BanUser (UserId user) (GroupId group) end comment ->
                    EncodedRequestInternal "control" "banUser"
                        [ ("user", EInt user)
                        , ("group", EInt group)
                        , ("end", ePosix end)
                        , ("comment", EString comment)
                        ]
                KickUser (UserId user) (GroupId group) ->
                    EncodedRequestInternal "control" "kickUser"
                        [ ("user", EInt user)
                        , ("group", EInt group)
                        ]
                RevokeBan (UserId user) (GroupId group) ->
                    EncodedRequestInternal "control" "revokeBan"
                        [ ("user", EInt user)
                        , ("group", EInt group)
                        ]
        RespInfo resp ->
            case resp of
                InstalledGameTypes ->
                    EncodedRequestInternal "info" "installedGameTypes"
                        []
                CreateOptions key ->
                    EncodedRequestInternal "info" "createOptions"
                        [ ("type", EString key)
                        ]
                Rolesets key ->
                    EncodedRequestInternal "info" "rolesets"
                        [ ("type", EString key)
                        ]
        RespMulti resp ->
            case resp of
                Multi lr ->
                    EncodedRequestInternal "multi" "multi"
                        [ ("tasks", EString <| encode 0 <| list encodeJson lr)]

encodeJson : Response -> Value
encodeJson response =
    let
        req = encodeRequestInternal response
        vars =  
            ("_class", EString req.class) ::
            ("_method", EString req.method) ::
            req.vars
    in object <| map
        (\(key, encv) ->
            ( key
            , case encv of
                EInt v -> int v
                EString v -> string v
            )
        )
        vars

encodeRequest : Response -> EncodedRequest
encodeRequest response =
    let
        req = encodeRequestInternal response
    in
        EncodedRequest req.class req.method <| map
            (\(k, ev) ->
                ( k
                , case ev of
                    EInt v -> String.fromInt v
                    EString v -> v
                )
            )
            req.vars
