module Game.Types.DecodeTypes exposing (..)

import Json.Decode exposing (..)
import Json.Decode.Pipeline exposing (decode, required)
import Game.Types.Types exposing (..)

decodeUserStat : Decoder UserStat
decodeUserStat =
    decode UserStat
        |> required "userId" int
        |> required "name" string
        |> required "gravatar" string
        |> required "firstGame" (nullable int)
        |> required "lastGame" (nullable int)
        |> required "gameCount" int
        |> required "winningCount" int
        |> required "moderatedCount" int
        |> required "lastOnline" int
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
        |> required "id" int
        |> required "name" string
        |> required "created" int
        |> required "lastTime" (nullable int)
        |> required "creator" int
        |> required "leader" int
        |> required "currentGame" (nullable decodeGame)
        |> required "enterKey" string

decodeGame : Decoder Game
decodeGame =
    decode Game
        |> required "id" int
        |> required "mainGroupId" int
        |> required "started" int
        |> required "finished" (nullable int)
        |> required "phase" string
        |> required "day" int
        |> required "ruleset" string
        |> required "winningRoles" (nullable (list string))

decodeUser : Decoder User
decodeUser =
    decode User
        |> required "group" int
        |> required "user" int
        |> required "player" (nullable decodePlayer)
        |> required "stats" decodeUserStat

decodePlayer : Decoder Player
decodePlayer =
    decode Player
        |> required "id" int
        |> required "game" int
        |> required "user" int
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
        |> required "id" int
        |> required "game" int
        |> required "chatRoom" string
        |> required "voting" (list decodeVoting)
        |> required "permission" decodePermission

decodeVoting : Decoder Voting
decodeVoting =
    decode Voting
        |> required "chat" int
        |> required "voteKey" string
        |> required "created" int
        |> required "voteStart" (nullable int)
        |> required "voteEnd" (nullable int)
        |> required "enabledUser" (list int)
        |> required "targetUser" (list int)
        |> required "result" (nullable int)

decodePermission : Decoder Permission
decodePermission =
    decode Permission
        |> required "enable" bool
        |> required "write" bool
        |> required "visible" bool
        |> required "player" (list int)

decodeChatEntry : Decoder ChatEntry
decodeChatEntry =
    decode ChatEntry
        |> required "id" int
        |> required "chat" int
        |> required "user" int
        |> required "text" string
        |> required "sendDate" int

decodeVote : Decoder Vote
decodeVote =
    decode Vote
        |> required "setting" int
        |> required "voteKey" string
        |> required "voter" int
        |> required "target" int
        |> required "date" int

decodeBanInfo : Decoder BanInfo
decodeBanInfo =
    decode BanInfo
        |> required "user" int
        |> required "spoker" int
        |> required "group" int
        |> required "startDate" int
        |> required "endDate" (maybe int)
        |> required "comment" string
