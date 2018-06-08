module Game.Types.Changes exposing
    ( Changes (..)
    , ChangeConfig
    , concentrate
    )

import Game.Types.Types exposing (..)
import Game.Types.CreateOptions exposing (..)
import Game.Types.Response exposing (..)
import Debug exposing (log)
import List
import Dict
import Json.Decode exposing (decodeValue, string, int)

type Changes
    = CUserStat UserStat
    | CGroup Group
    | CGame Game
    | CUser User
    | CChat Chat
    | CChatEntry ChatEntry
    | CVote Vote
    | CVoting Voting
    | CLastOnline Int (List (Int, Int))
    | CInstalledGameTypes (List String)
    | CCreateOptions String CreateOptions
    | CRolesets String (List String)
    | CConfig (Maybe String)
    | COwnId Int
    | CAccountInvalid
    | CNetworkError
    | CMaintenance
    | CErrInvalidGroupKey
    
type alias ChangeConfig =
    { changes: List Changes
    , reload: Bool
    }

concentrate : Response -> ChangeConfig
concentrate resp =
    case resp.result of
        RGet r ->
            case r of
                GetUserStats v ->
                    ChangeConfig [ CUserStat v ] False
                GetOwnUserStat v ->
                    ChangeConfig [ COwnId v.userId, CUserStat v ] False
                GetGroup v ->
                    ChangeConfig [ CGroup v ] False
                GetUser v ->
                    ChangeConfig [ CUser v ] False
                GetUserFromGroup v ->
                    ChangeConfig (List.map CUser v) False
                GetMyGroupUser v ->
                    ChangeConfig (List.map CUser v) False
                GetChatRoom v ->
                    ChangeConfig [ CChat v ] False
                GetChatRooms v ->
                    ChangeConfig (List.map CChat v) False
                GetChatEntrys v ->
                    ChangeConfig (List.map CChatEntry v) False
                GetVotes v ->
                    ChangeConfig (List.map CVote v) False
                GetConfig c ->
                    ChangeConfig [ CConfig c ] False
        RConv r -> 
            case r of
                LastOnline v ->
                    let t = Dict.get "group" resp.info.request
                        dv = Maybe.andThen 
                            (Result.toMaybe << decodeValue int) t
                    in case dv of
                        Just ti -> 
                            ChangeConfig [ CLastOnline ti v ] False
                        Nothing -> ChangeConfig [] False
                GetUpdatedGroup v ->
                    case v of
                        Just g -> ChangeConfig [ CGroup g ] False
                        Nothing -> ChangeConfig [] False
                GetChangedVotings v ->
                    ChangeConfig (List.map CVoting v) False
                GetNewChatEntrys v ->
                    ChangeConfig (List.map CChatEntry v) False
                GetNewVotes v ->
                    ChangeConfig (List.map CVote v) False
        RControl r -> 
            case r of
                CreateGroup v ->
                    ChangeConfig [ CGroup v ] False
                JoinGroup v -> 
                    ChangeConfig [ CGroup v ] False
                ChangeLeader v ->
                    ChangeConfig [ CGroup v ] False
                StartNewGame v ->
                    ChangeConfig [ CGame v ] False
                NextPhase v ->
                    ChangeConfig [ CGame v ] False
                PostChat v ->
                    ChangeConfig [ CChatEntry v ] False
                StartVoting v ->
                    ChangeConfig [ CVoting v ] False
                FinishVoting ->
                    ChangeConfig [] False
                Vote_ v ->
                    ChangeConfig [ CVote v ] False
                SetConfig c ->
                    ChangeConfig [ CConfig <| Just c ] False
        RInfo r ->  
            case r of
                InstalledGameTypes v ->
                    ChangeConfig [ CInstalledGameTypes v ] False
                CreateOptions_ v ->
                    let
                        t = Dict.get "type" resp.info.request
                        dv = Maybe.map (decodeValue string) t
                    in case dv of
                        Just ti ->
                            case ti of
                                Ok rv -> ChangeConfig [ CCreateOptions rv v ] False
                                Err _ -> ChangeConfig [] False
                        Nothing -> ChangeConfig [] False
                InstalledRoles v ->
                    ChangeConfig [] False
                Rolesets v ->
                    let
                        t = Dict.get "type" resp.info.request
                        dv = Maybe.map (decodeValue string) t
                    in case dv of
                        Just ti ->
                            case ti of
                                Ok rv ->
                                    ChangeConfig [ CRolesets rv v ] False
                                Err _ ->
                                    ChangeConfig [] False
                        Nothing ->
                            ChangeConfig [] False
        RMulti r -> 
            case r of
                Multi v ->
                    let
                        c = List.map concentrate v
                        rl = List.concat (List.map .changes c)
                        rb = List.foldr (||) False (List.map .reload c)
                    in ChangeConfig rl rb
        RError e -> case e.key of
            "account" -> ChangeConfig [ CAccountInvalid ] False
            "maintenance" -> ChangeConfig [ CMaintenance ] False
            "wrongId" -> case resp.info.class of
                "control" -> case resp.info.method of
                    "joinGroup" -> case e.info of
                        "group key not found in db" -> ChangeConfig [ CErrInvalidGroupKey ] False
                        _ -> handleError resp
                    _ -> handleError resp
                _ -> handleError resp
            _ -> handleError resp

handleError : Response -> ChangeConfig
handleError resp =
    let d = log "server error" resp
        r = ChangeConfig [] False
    in  always r d
