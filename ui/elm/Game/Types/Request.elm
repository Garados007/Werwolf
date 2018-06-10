module Game.Types.Request exposing
    ( UserId, GroupId, ChatId, GameId, VoteKey, PlayerId
    , GroupVersion, NewGameConfig
    , Response (..)
    , ResponseGet (..)
    , ResponseConv (..)
    , ResponseControl (..)
    , ResponseInfo (..)
    , ResponseMulti (..)
    , EncodedRequest
    , encodeJson
    , encodeRequest
    )

import Json.Encode exposing (Value, object, string, int, list, encode)
import List exposing (map)
import Dict exposing (Dict)

type alias UserId = Int
type alias GroupId = Int
type alias ChatId = Int
type alias GameId = Int
type alias VoteKey = String
type alias PlayerId = Int

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

type ResponseConv
    = LastOnline GroupId
    | GetUpdatedGroup GroupVersion
    | GetChangedVotings GameId Int --LastChange
    | GetNewChatEntrys ChatId Int --After
    | GetAllNewChatEntrys GameId Int --AfterId
    | GetNewVotes ChatId VoteKey Int --LastChange
    
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

encodeRequestInternal : Response -> EncodedRequestInternal
encodeRequestInternal response =
    case response of
        RespGet resp ->
            case resp of
                GetUserStats userId ->
                    EncodedRequestInternal "get" "getUserStats"
                        [ ("user", EInt userId)
                        ]
                GetOwnUserStat ->
                    EncodedRequestInternal "get" "getOwnUserStat"
                        []
                GetGroup groupId ->
                    EncodedRequestInternal "get" "getGroup"
                        [ ("group", EInt groupId)
                        ]
                GetUser groupId userId ->
                    EncodedRequestInternal "get" "getUser"
                        [ ("group", EInt groupId)
                        , ("user", EInt userId)
                        ]
                GetUserFromGroup groupId ->
                    EncodedRequestInternal "get" "getUserFromGroup"
                        [ ("group", EInt groupId)
                        ]
                GetMyGroupUser ->
                    EncodedRequestInternal "get" "getMyGroupUser"
                        []
                GetChatRoom chatId ->
                    EncodedRequestInternal "get" "getChatRoom"
                        [ ("chat", EInt chatId)
                        ]
                GetChatRooms gameId ->
                    EncodedRequestInternal "get" "getChatRooms"
                        [ ("game", EInt gameId)
                        ]
                GetChatEntrys chatId ->
                    EncodedRequestInternal "get" "getChatEntrys"
                        [ ("chat", EInt chatId)
                        ]
                GetVotes chatId voteKey ->
                    EncodedRequestInternal "get" "getVotes"
                        [ ("chat", EInt chatId)
                        , ("voteKey", EString voteKey)
                        ]
                GetConfig ->
                    EncodedRequestInternal "get" "getConfig"
                        []
        RespConv resp ->
            case resp of
                LastOnline groupId ->
                    EncodedRequestInternal "conv" "lastOnline"
                        [ ("group", EInt groupId)
                        ]
                GetUpdatedGroup gv ->
                    EncodedRequestInternal "conv" "getUpdatedGroup"
                        (
                            [ ("group", EInt gv.group)
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
                GetChangedVotings gameId lastChange ->
                    EncodedRequestInternal "conv" "getChangedVotings"
                        [ ("game", EInt gameId)
                        , ("lastChange", EInt lastChange)
                        ]
                GetNewChatEntrys chatId after ->
                    EncodedRequestInternal "conv" "getNewChatEntrys"
                        [ ("chat", EInt chatId)
                        , ("after", EInt after)
                        ]
                GetAllNewChatEntrys gameId after ->
                    EncodedRequestInternal "conv" "getAllNewChatEntrys"
                        [ ("game", EInt gameId)
                        , ("after", EInt after)
                        ]
                GetNewVotes chatId voteKey lastChange ->
                    EncodedRequestInternal "conv" "getNewVotes"
                        [ ("chat", EInt chatId)
                        , ("voteKey", EString voteKey)
                        , ("lastChange", EInt lastChange)
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
                ChangeLeader groupId userId ->
                    EncodedRequestInternal "control" "changeLeader"
                        [ ("group", EInt groupId)
                        , ("leader", EInt userId)
                        ]
                StartNewGame ng ->
                    EncodedRequestInternal "control" "startNewGame"
                        [ ("group", EInt ng.group)
                        , ("roles", EString <| encode 0 <| object <| 
                            List.map (\(k,v) -> (k,int v)) <|
                            Dict.toList ng.roles)
                        , ("ruleset", EString ng.ruleset)
                        , ("config", EString <| encode 0 ng.config)
                        ]
                NextPhase gameId ->
                    EncodedRequestInternal "control" "nextPhase"
                        [ ("game", EInt gameId)
                        ]
                PostChat chatId chat ->
                    EncodedRequestInternal "control" "postChat"
                        [ ("chat", EInt chatId)
                        , ("text", EString chat)
                        ]
                StartVoting chatId voteKey ->
                    EncodedRequestInternal "control" "startVoting"
                        [ ("chat", EInt chatId)
                        , ("voteKey", EString voteKey)
                        ]
                FinishVoting chatId voteKey ->
                    EncodedRequestInternal "control" "finishVoting"
                        [ ("chat", EInt chatId)
                        , ("voteKey", EString voteKey)
                        ]
                Vote chatId voteKey playerId ->
                    EncodedRequestInternal "control" "vote"
                        [ ("chat", EInt chatId)
                        , ("voteKey", EString voteKey)
                        , ("target", EInt playerId)
                        ]
                SetConfig config ->
                    EncodedRequestInternal "control" "setConfig"
                        [ ("config", EString config)
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
                        [ ("tasks", EString <| encode 0 <| list <| map encodeJson lr)]

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
                    EInt v -> toString v
                    EString v -> v
                )
            )
            req.vars
