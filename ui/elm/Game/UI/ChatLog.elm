module Game.UI.ChatLog exposing 
    ( ChatTile (..)
    , ChatLog
    , view
    , init
    , update
    , Msg 
    , Event (..)
    , msgAdd
    , msgSet
    , msgUpdateUser
    , msgUpdateChat
    , msgUpdateFilter
    , detector
    )

import Html exposing (Html,div)
import Html.Attributes exposing (class,id)
import Html.Lazy exposing (lazy)
import List
import Time exposing (Posix,Zone)
import Time.Extra exposing (diff, Interval (..))
import Task exposing (perform,attempt)
import Dict

import Game.UI.ChatPostTile as ChatPostTile
import Game.Utils.Language exposing (LangLocal, decodeSpecial)
import Game.Types.Types as Types exposing (ChatId (..), UserId, GroupId (..), ChatEntry)
import Game.Data as Data exposing (Data)
import DataDiff.Path as Diff exposing (DetectorPath, Path (..))
import DataDiff.Ex exposing (SingleActionEx (..), ModActionEx (..))
import UnionDict

-- elm/browser
import Browser.Dom as Dom

type ChatTile
    = PostTile ChatPostTile.ChatPostTile

type ChatLog = Internal IntChatLog

type alias IntChatLog =
    { id : GroupId
    , items : List ChatTile
    , filter : Maybe ChatId
    }

type Msg
    = Add ChatTile
    | Set (List ChatTile)
    | UpdateUser UserId String
    | UpdateChat ChatId String
    | UpdateFilter (Maybe ChatId)
    | NoOp1
    -- data detectors
    | PathEntryAdded ChatEntry
    -- init msg 
    | AddMassive (List ChatEntry)

type Event 
    = ReqData (Data -> Msg)

msgAdd : ChatTile -> Msg 
msgAdd = Add

msgSet : List ChatTile -> Msg 
msgSet = Set

msgUpdateUser : UserId -> String -> Msg 
msgUpdateUser = UpdateUser

msgUpdateChat : ChatId -> String -> Msg 
msgUpdateChat = UpdateChat

msgUpdateFilter : Maybe ChatId -> Msg 
msgUpdateFilter = UpdateFilter

detector : ChatLog -> DetectorPath Data Msg
detector (Internal log) = Data.pathGameData
    <| Data.pathGroupData []
    <| Diff.cond
        (\_ _ group -> group.group.id == log.id )
    <| Diff.batch
    [ Data.pathChatData []
        <| Data.pathSafeDictInt "entry" .entry
            [ AddedEx <| always PathEntryAdded
            ]
        <| Diff.value []
    , Diff.goPath (PathString "user") .user 
        <| Diff.list
            (\_ _ -> PathInt)
            []
        <| Diff.mapData .stats
        <| Diff.value
            [ ChangedEx <| \_ old new ->
                if old.name /= new.name
                then UpdateUser new.userId new.name
                else NoOp1
            ]
    , Data.pathChatData []
        <| Diff.mapData .chat
        <| Diff.value 
            [ ChangedEx <| \_ old new ->
                if old.chatRoom /= new.chatRoom
                then UpdateChat new.id new.chatRoom
                else NoOp1
            ]
    ]

toBottom : String -> Cmd Msg 
toBottom id = Dom.getViewportOf id
    |> Task.andThen 
        (\info -> Dom.setViewportOf
            id
            0
            info.scene.height
        )
    |> Task.attempt (\_ -> NoOp1)

init : GroupId -> (ChatLog, List Event)
init id = 
    ( Internal (IntChatLog id [] Nothing)
    , List.singleton <| ReqData 
        (\data -> data.game.groups
            |> UnionDict.unsafen GroupId Types.groupId 
            |> UnionDict.get id 
            |> Maybe.map .chats 
            |> Maybe.withDefault (UnionDict.include Dict.empty)
            |> UnionDict.unsafen ChatId Types.chatId 
            |> UnionDict.values 
            |> List.concatMap 
                ( .entry 
                    >> UnionDict.unsafen Types.ChatEntryId Types.chatEntryId
                    >> UnionDict.values
                )
            |> AddMassive
        )
    )

view : Data -> LangLocal -> ChatLog -> Html Msg
view data lang (Internal log) =
    div [ class "chat-log"
        , id 
            <| String.fromInt 
            <| Types.groupId log.id 
        ]
        <| List.filterMap
            (\tile -> case tile of
                PostTile t -> case log.filter of
                    Nothing -> Just <| lazy (ChatPostTile.view data lang) t
                    Just id ->
                        if Types.ChatId t.chatId == id
                        then Just <| lazy (ChatPostTile.view data lang) t
                        else Nothing
            )
            log.items

update : Msg -> ChatLog -> (ChatLog, Cmd Msg, List Event)
update msg (Internal model) =
    case msg of
        Add tile ->
            let
                contains = case tile of
                    PostTile tile1 -> List.any
                        (\t -> case t of
                            PostTile tile2 -> tile1.id == tile2.id
                        )
                        model.items
                list = if contains then model.items else List.append model.items [ tile ]
                cmd = 
                    if contains 
                    then Cmd.none 
                    else toBottom 
                        <| String.fromInt
                        <| Types.groupId model.id
            in  (Internal { model | items = sortTiles list }
                , cmd
                , []
                )
        Set tiles ->
            let
                cmd = toBottom 
                    <| String.fromInt
                    <| Types.groupId model.id
            in  (Internal { model | items = sortTiles tiles }
                , cmd
                , []
                )
        UpdateUser userId name ->
            (Internal { model | items = List.map
                (\item ->
                    case item of
                        PostTile tile ->
                            if Types.UserId tile.userId == userId
                            then PostTile { tile | userName = name }
                            else PostTile tile
                )
                model.items
            }
            , Cmd.none
            , []
            )
        UpdateChat chatId name ->
            (Internal { model | items = List.map
                (\item ->
                    case item of
                        PostTile tile ->
                            if Types.ChatId tile.chatId == chatId
                            then PostTile { tile | chat = name }
                            else PostTile tile
                )
                model.items
            }
            , Cmd.none
            , []
            )
        UpdateFilter filter ->
            (Internal { model | filter = filter }, Cmd.none, [])
        NoOp1 -> (Internal model, Cmd.none, [])
        PathEntryAdded entry -> 
            ( Internal model
            , Cmd.none
            , List.singleton <| ReqData <| \data ->
                Add <| PostTile
                    { userName = data.game.groups
                        |> UnionDict.unsafen GroupId Types.groupId 
                        |> UnionDict.get model.id
                        |> Maybe.map .user 
                        |> Maybe.withDefault []
                        |> List.filter ((==) entry.user << .user)
                        |> List.head 
                        |> Maybe.map (.stats >> .name)
                        |> Maybe.withDefault 
                            ((++) "User #" 
                                <| String.fromInt 
                                <| Types.userId entry.user
                            )
                    , userId = Types.userId entry.user
                    , time = entry.sendDate
                    , chat = data.game.groups
                        |> UnionDict.unsafen GroupId Types.groupId 
                        |> UnionDict.get model.id
                        |> Maybe.map .chats 
                        |> Maybe.withDefault (UnionDict.include Dict.empty)
                        |> UnionDict.unsafen ChatId Types.chatId 
                        |> UnionDict.get entry.chat 
                        |> Maybe.map (.chat >> .chatRoom)
                        |> Maybe.withDefault 
                            ((++) "Chat #" 
                                <| String.fromInt 
                                <| Types.chatId entry.chat
                            )
                    , chatId = Types.chatId entry.chat
                    , text = entry.text
                    , special = decodeSpecial entry.text
                    , id = Types.chatEntryId entry.id
                    }
            )
        AddMassive entries -> List.foldr
            (\e (m, c, list) -> update (PathEntryAdded e) m
                |> \(rm, _, rlist) ->
                    (rm, c, rlist ++ list)                
            )
            (Internal model, Cmd.none, [])
            entries

sortTiles : List ChatTile -> List ChatTile
sortTiles = List.sortWith
    (\a b ->
        let (at,ai) = timeId a
            (bt,bi) = timeId b
        in case compare 0 <| diff Millisecond Time.utc at bt of
            EQ -> compare ai bi
            LT -> LT
            GT -> GT
    )

timeId : ChatTile -> (Posix,Int)
timeId tile = case tile of
    PostTile t -> (t.time, t.userId)