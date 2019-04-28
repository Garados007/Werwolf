module Game.Types.DecodeTypes exposing (..)

import Json.Decode exposing (..)
import Json.Decode.Pipeline exposing (required)
import Game.Types.Types exposing (..)
import Time exposing (Posix)

decode = succeed

dposix : Decoder Posix
dposix = map (Time.millisToPosix << (*) 1000) int

decodeUserStat : Decoder UserStat
decodeUserStat =
    decode UserStat
        |> required "userId" (map UserId int)
        |> required "name" string
        |> required "gravatar" string
        |> required "firstGame" (nullable dposix)
        |> required "lastGame" (nullable dposix)
        |> required "gameCount" int
        |> required "winningCount" int
        |> required "moderatedCount" int
        |> required "lastOnline" dposix
        |> required "aiId" (nullable int)
        |> required "aiNameKey" (nullable string)
        |> required "aiControlClass" (nullable string)
        |> required "totalBanCount" int
        |> required "totalBanDays" int
        |> required "permaBanCount" int
        |> required "spokenBanCount" int

decodeGroup : Decoder Group
decodeGroup =
    decode Group
        |> required "id" (map GroupId int)
        |> required "name" string
        |> required "created" dposix
        |> required "lastTime" (nullable dposix)
        |> required "creator" (map UserId int)
        |> required "leader" (map UserId int)
        |> required "currentGame" (nullable decodeGame)
        |> required "enterKey" string

decodeGame : Decoder Game
decodeGame =
    decode Game
        |> required "id" (map GameId int)
        |> required "mainGroupId" (map GroupId int)
        |> required "started" dposix
        |> required "finished" (nullable dposix)
        |> required "phase" string
        |> required "day" int
        |> required "ruleset" string
        |> required "winningRoles" (nullable (list string))

decodeUser : Decoder User
decodeUser =
    decode User
        |> required "group" (map GroupId int)
        |> required "user" (map UserId int)
        |> required "player" (nullable decodePlayer)
        |> required "stats" decodeUserStat

decodePlayer : Decoder Player
decodePlayer =
    decode Player
        |> required "id" (map PlayerId int)
        |> required "game" (map GameId int)
        |> required "user" (map UserId int)
        |> required "alive" bool
        |> required "roles" (list decodeRole)

decodeRole : Decoder Role
decodeRole =
    decode Role
        |> required "roleKey" string
        |> required "index" int

decodeChat : Decoder Chat
decodeChat =
    decode Chat
        |> required "id" (map ChatId int)
        |> required "game" (map GameId int)
        |> required "chatRoom" string
        |> required "voting" (list decodeVoting)
        |> required "permission" decodePermission

decodeVoting : Decoder Voting
decodeVoting =
    decode Voting
        |> required "chat" (map ChatId int)
        |> required "voteKey" (map VoteKey string)
        |> required "created" dposix
        |> required "voteStart" (nullable dposix)
        |> required "voteEnd" (nullable dposix)
        |> required "enabledUser" (list <| map PlayerId int)
        |> required "targetUser" (list <| map PlayerId int)
        |> required "result" (nullable <| map PlayerId int)

decodePermission : Decoder Permission
decodePermission =
    decode Permission
        |> required "enable" bool
        |> required "write" bool
        |> required "visible" bool
        |> required "player" (list <| map PlayerId int)

decodeChatEntry : Decoder ChatEntry
decodeChatEntry =
    decode ChatEntry
        |> required "id" (map ChatEntryId int)
        |> required "chat" (map ChatId int)
        |> required "user" (map UserId int)
        |> required "text" string
        |> required "sendDate" dposix

decodeVote : Decoder Vote
decodeVote =
    decode Vote
        |> required "setting" (map ChatId int)
        |> required "voteKey" (map VoteKey string)
        |> required "voter"  (map PlayerId int)
        |> required "target" (map PlayerId int)
        |> required "date" dposix

decodeBanInfo : Decoder BanInfo
decodeBanInfo =
    decode BanInfo
        |> required "user" (map UserId int)
        |> required "spoker" (map UserId int)
        |> required "group" (map GroupId int)
        |> required "startDate" dposix
        |> required "endDate" (maybe dposix)
        |> required "comment" string
