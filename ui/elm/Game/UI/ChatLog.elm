module Game.UI.ChatLog exposing 
    ( ChatTile (..)
    , ChatLog
    , view
    , init
    , update
    , Msg 
    , msgAdd
    , msgSet
    , msgUpdateUser
    , msgUpdateChat
    , msgUpdateFilter
    )

import Html exposing (Html,div)
import Html.Attributes exposing (class,id)
import Html.Lazy exposing (lazy)
import List
import Time exposing (Posix,Zone)
import Time.Extra exposing (diff, Interval (..))
import Task exposing (perform,attempt)

import Game.UI.ChatPostTile as ChatPostTile
import Game.Types.Request exposing (ChatId,UserId)
import Game.Configuration exposing (..)

-- elm/browser
import Browser.Dom as Dom

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
    | NoOp1

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

toBottom : String -> Cmd Msg 
toBottom id = Dom.getViewportOf id
    |> Task.andThen 
        (\info -> Dom.setViewportOf
            id
            0
            info.scene.height
        )
    |> Task.attempt (\_ -> NoOp1)

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
                contains = case tile of
                    PostTile tile1 -> List.any
                        (\t -> case t of
                            PostTile tile2 -> tile1.id == tile2.id
                        )
                        model.items
                list = if contains then model.items else List.append model.items [ tile ]
                cmd = if contains then Cmd.none else toBottom model.id
            in (Internal { model | items = sortTiles list }, cmd)
        Set tiles ->
            let
                cmd = toBottom model.id
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
        NoOp1 -> (Internal model, Cmd.none)

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