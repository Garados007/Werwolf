module Game.UI.ChatLog exposing 
    ( ChatTile (..)
    , ChatLog
    , view
    , init
    , update
    , Msg 
        ( Add
        , Set
        , UpdateUser
        , UpdateChat
        , UpdateFilter
        )
    )

import Dom
import Dom.Scroll exposing (toBottom)
import Html exposing (program,Html,div)
import Html.Attributes exposing (class,id)
import Html.Lazy exposing (lazy)
import List
import Time exposing (Time)
import Task exposing (perform,attempt)

import Game.UI.ChatPostTile as ChatPostTile
import Game.Types.Request exposing (ChatId,UserId)
import Game.Utils.Dates exposing (DateTimeFormat)
import Game.Configuration exposing (..)

type ChatTile
    = PostTile ChatPostTile.ChatPostTile

type ChatLog = Internal IntChatLog

type alias IntChatLog =
    { id : String
    , items : List ChatTile
    , filter : Maybe ChatId
    }

type Msg
    = Add ChatTile
    | Set (List ChatTile)
    | UpdateUser UserId String
    | UpdateChat ChatId String
    | UpdateFilter (Maybe ChatId)
    | NoOp1 (Result Dom.Error ())

init : String -> ChatLog
init id = Internal (IntChatLog id [] Nothing)

view : LangConfiguration -> ChatLog -> Html Msg
view config (Internal log) =
    div [ class "chat-log", id log.id ] <|
        List.filterMap
            (\tile -> case tile of
                PostTile t -> case log.filter of
                    Nothing -> Just <| lazy (ChatPostTile.view config) t
                    Just id ->
                        if t.chatId == id
                        then Just <| lazy (ChatPostTile.view config) t
                        else Nothing
            )
            log.items

update : Msg -> ChatLog -> (ChatLog, Cmd Msg)
update msg (Internal model) =
    case msg of
        Add tile ->
            let
                list = List.append model.items [ tile ]
                cmd = attempt NoOp1 (toBottom model.id)
            in (Internal { model | items = sortTiles list }, cmd)
        Set tiles ->
            let
                cmd = attempt NoOp1 (toBottom model.id)
            in (Internal { model | items = sortTiles tiles }, cmd)
        UpdateUser userId name ->
            (Internal { model | items = List.map
                (\item ->
                    case item of
                        PostTile tile ->
                            if tile.userId == userId
                            then PostTile { tile | userName = name }
                            else PostTile tile
                )
                model.items
            }, Cmd.none)
        UpdateChat chatId name ->
            (Internal { model | items = List.map
                (\item ->
                    case item of
                        PostTile tile ->
                            if tile.chatId == chatId
                            then PostTile { tile | chat = name }
                            else PostTile tile
                )
                model.items
            }, Cmd.none)
        UpdateFilter filter ->
            (Internal { model | filter = filter }, Cmd.none)
        NoOp1 _ -> (Internal model, Cmd.none)

sortTiles : List ChatTile -> List ChatTile
sortTiles = List.sortWith
    (\a b ->
        let (at,ai) = timeId a
            (bt,bi) = timeId b
        in case compare at bt of
            EQ -> compare ai bi
            LT -> LT
            GT -> GT
    )

timeId : ChatTile -> (Time,Int)
timeId tile = case tile of
    PostTile t -> (t.time, t.userId)