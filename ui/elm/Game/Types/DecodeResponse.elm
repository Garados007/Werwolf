module Game.Types.DecodeResponse exposing 
    ( decodeResponse
    )

import Game.Types.Response exposing (..)
import Maybe

import Game.Types.DecodeTypes exposing (..)
import Game.Types.DecodeCreateOptions exposing (..)

import Json.Decode exposing (..)
import Json.Decode.Pipeline exposing (required)
import Dict
import Game.Types.Types exposing (UserId (..))

decode = succeed

decodeResponse : Decoder Response
decodeResponse =
    andThen
        (\info ->
            andThen
                (\error ->
                    case error of
                        Just e ->
                            succeed (Response info 
                                (RError e))
                        Nothing ->
                            map (Response info)
                                (decodeResult info.class info.method)
                )
                decodeError
        )
        decodeResponseInfo

decodeResponseInfo : Decoder ResponseInfo
decodeResponseInfo =
    decode ResponseInfo
        |> required "class" string
        |> required "method" string
        |> required "request"
            ( oneOf
                [ dict value
                , andThen
                    (\list ->
                        if List.isEmpty list
                        then succeed Dict.empty
                        else fail "Require object of values or an empty array"
                    )
                    <| list int
                ]

            )

decodeError : Decoder (Maybe ErrorInfo)
decodeError =
    maybe (field "error"
        ( decode ErrorInfo
            |> required "key" string
            |> required "info" string
        )
    )

decodeResult : String -> String -> Decoder Game.Types.Response.Result
decodeResult class method =
    andThen
        (\v -> 
            case v of
                Just r -> succeed r
                Nothing -> fail "class or method not found"
        )
        (case class of
            "get" ->
                map (Maybe.map RGet) (decodeGet method)
            "conv" ->
                map (Maybe.map RConv) (decodeConv method)
            "control" ->
                map (Maybe.map RControl) (decodeControl method)
            "info" ->
                map (Maybe.map RInfo) (decodeInfo method)
            "multi" ->
                map (Maybe.map RMulti) (decodeMulti method)
            _ -> succeed Nothing
        )

decodeGet : String -> Decoder (Maybe ResultGet)
decodeGet method =
    case method of
        "getUserStats" ->
            decSingle GetUserStats decodeUserStat
        "getOwnUserStat" ->
            decSingle GetOwnUserStat decodeUserStat
        "getGroup" ->
            decSingle GetGroup decodeGroup
        "getUser" ->
            decSingle GetUser decodeUser
        "getUserFromGroup" ->
            decSingle GetUserFromGroup (list decodeUser)
        "getMyGroupUser" ->
            decSingle GetMyGroupUser (list decodeUser)
        "getChatRoom" ->
            decSingle GetChatRoom decodeChat
        "getChatRooms" ->
            decSingle GetChatRooms (list decodeChat)
        "getChatEntrys" ->
            decSingle GetChatEntrys (list decodeChatEntry)
        "getVotes" ->
            decSingle GetVotes (list decodeVote)
        "getConfig" ->
            decSingle GetConfig (maybe string)
        "topUser" ->
            decSingle TopUser (list decodeUserStat)
        "getAllBansOfUser" ->
            decSingle GetAllBansOfUser (list decodeBanInfo)
        "getNewestBans" ->
            decSingle GetNewestBans (list decodeBanInfo)
        "getOldestBans" ->
            decSingle GetOldestBans (list decodeBanInfo)
        "getUserSpokenBans" ->
            decSingle GetUserSpokenBans (list decodeBanInfo)
        "getBansFromGroup" ->
            decSingle GetBansFromGroup (list decodeBanInfo)
        _ -> succeed Nothing

decodeConv : String -> Decoder (Maybe ResultConv)
decodeConv method =
    case method of
        "lastOnline" ->
            decSingle LastOnline (list (decodeTuple2 (map UserId int) dposix))
        "getUpdatedGroup" ->
            decSingle GetUpdatedGroup (nullable decodeGroup)
        "getChangedVotings" ->
            decSingle GetChangedVotings (list decodeVoting)
        "getNewChatEntrys" ->
            decSingle GetNewChatEntrys (list decodeChatEntry)
        "getAllNewChatEntrys" ->
            decSingle GetAllNewChatEntrys (list decodeChatEntry)
        "getNewVotes" ->
            decSingle GetNewVotes (list decodeVote)
        _ -> succeed Nothing

decodeControl : String -> Decoder (Maybe ResultControl)
decodeControl method =
    case method of
        "createGroup" ->
            decSingle CreateGroup decodeGroup
        "joinGroup" ->
            decSingle JoinGroup decodeGroup
        "changeLeader" ->
            decSingle ChangeLeader decodeGroup
        "startNewGame" ->
            decSingle StartNewGame decodeGame
        "nextPhase" ->
            decSingle NextPhase decodeGame
        "postChat" ->
            decSingle PostChat decodeChatEntry
        "startVoting" ->
            decSingle StartVoting decodeVoting
        "finishVoting" ->
            decSingle (always FinishVoting) bool
            --succeed (Just FinishVoting)
        "vote" ->
            decSingle Vote_ decodeVote
        "setConfig" ->
            decSingle SetConfig string
        "leaveGroup" ->
            decSingle (always LeaveGroup) bool
        "banUser" ->
            decSingle BanUser decodeBanInfo
        "kickUser" ->
            decSingle (always KickUser) bool
        "revokeBan" ->
            decSingle RevokeBan decodeBanInfo
        _ -> succeed Nothing

decodeInfo : String -> Decoder (Maybe ResultInfo)
decodeInfo method =
    case method of
        "installedGameTypes" ->
            decSingle InstalledGameTypes (list string)
        "createOptions" ->
            decSingle CreateOptions_ decodeCreateOptions
        "installedRoles" ->
            decSingle InstalledRoles (list string)
        "rolesets" ->
            decSingle Rolesets (list string)
        _ -> succeed Nothing

decodeMulti : String -> Decoder (Maybe ResultMulti)
decodeMulti method =
    case method of
        "multi" ->
            decSingle Multi (list decodeResponse)
        _ -> succeed Nothing

decSingle : (a -> b) -> Decoder a -> Decoder (Maybe b)
decSingle f d = andThen (succeed << Just << f) (field "result" d)

decodeTuple2 : Decoder a -> Decoder b -> Decoder (a,b)
decodeTuple2 decoder1 decoder2=
    map2 
        (\a b -> (a,b))
        (index 0 decoder1)
        (index 1 decoder2)