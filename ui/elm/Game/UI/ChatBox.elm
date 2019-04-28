module Game.UI.ChatBox exposing
    ( ChatBox
    , ChatBoxMsg
    , ChatBoxEvent (..)
    , init
    , update
    , view
    , detector
    )

import Game.UI.ChatLog as ChatLog exposing (..)
import Game.UI.ChatPostTile as ChatPostTile exposing (..)
import Game.UI.ChatInsertBox as ChatInsertBox exposing (..)
import Game.Types.Types as Types exposing (..)
import Game.Types.Request exposing (Request (..), RequestControl (..))
import Game.Utils.Language exposing (..)
import Game.Data as Data exposing (Data)
import UnionDict exposing (UnionDict)
import DataDiff.Path as Diff exposing (DetectorPath, Path (..))
import DataDiff.Ex exposing (SingleActionEx (..), ModActionEx (..))

import Html exposing (Html,div,select,option,node,text)
import Html.Attributes exposing (class,title,value,attribute,selected)
import Html.Events exposing (on,onClick)
import Html.Lazy exposing (lazy)
import Dict exposing (Dict)
import Time exposing (Zone)
import Json.Decode as Json
import Task

type ChatBox = ChatBox ChatBoxInfo

type alias ChatBoxInfo =
    { ownGroupId : GroupId
    , chatLog : ChatLog
    , insertBox : ChatInsertBox.Model
    , selected : Maybe ChatId
    , targetChat : Maybe ChatId
    }

type ChatBoxMsg
    -- public methods
    -- Wrapped
    = WrapChatLog ChatLog.Msg
    | WrapChatInsertBox ChatInsertBox.Msg
    -- private
    | ChangeFilter String
    | ChangeVisible String
    | OnViewUser
    | OnViewVotes

type ChatBoxEvent
    = ViewUser
    | ViewVotes
    | Send Request
    | ReqData (Data -> ChatBoxMsg)

detector : ChatBox -> DetectorPath Data ChatBoxMsg 
detector (ChatBox info) = Diff.batch
    [ Diff.mapMsg WrapChatLog <| ChatLog.detector info.chatLog
    , Diff.cond (\_ _ _ -> info.targetChat == Nothing)
        <| Data.pathGameData
        <| Data.pathGroupData []
        <| Data.pathChatData
            [ AddedEx <| \_ c -> ChangeVisible
                <| String.fromInt
                <| Types.chatId
                <| c.chat.id
            ]
        <| Diff.noOp
    ]

init : GroupId -> (ChatBox, Cmd ChatBoxMsg, List ChatBoxEvent)
init group =
    let
        (cl, ev) = ChatLog.init group
        (cb, cbCmd) = ChatInsertBox.init
    in  ( ChatBox 
            { ownGroupId = group
            , chatLog = cl
            , insertBox = cb
            , selected = Nothing
            , targetChat = Nothing
            }
        , Cmd.map WrapChatInsertBox cbCmd
        , List.map mapChatLogEvent ev ++
            [ ReqData <| \data -> ChangeVisible
                <| Maybe.withDefault ""
                <| Maybe.map (.chat >> .id >> Types.chatId >> String.fromInt)
                <| List.head
                <| List.filter (.chat >> .permission >> .write)
                <| UnionDict.values
                <| Data.getChats
                <| Data.getGroup group data
            ]
        )

mapChatLogEvent : ChatLog.Event -> ChatBoxEvent 
mapChatLogEvent event = case event of 
    ChatLog.ReqData fun ->
        ReqData <| WrapChatLog << fun

update : ChatBoxMsg -> ChatBox -> (ChatBox, Cmd ChatBoxMsg, List ChatBoxEvent)
update msg (ChatBox model) =
    case msg of
        WrapChatLog wmsg ->
            let (wm, wcmd, ev) = ChatLog.update 
                    wmsg model.chatLog
            in  ( ChatBox { model | chatLog = wm}
                , Cmd.map WrapChatLog wcmd
                , List.map mapChatLogEvent ev
                )
        WrapChatInsertBox wmsg -> 
            let (wm, wcmd, wt) = ChatInsertBox.update wmsg model.insertBox
                (tm, task, tpm) = handle
                    { model | insertBox = wm } 
                    wt
            in  ( ChatBox tm
                , Cmd.batch
                    [ task
                    , Cmd.map WrapChatInsertBox wcmd
                    ]
                , tpm
                )
        ChangeFilter filter ->
            let
                filt = Maybe.map ChatId <| String.toInt filter
                (wm, wcmd, ev) = ChatLog.update (msgUpdateFilter filt) model.chatLog
            in  ( ChatBox { model | selected = filt, chatLog = wm }
                , Cmd.map WrapChatLog wcmd
                , List.map mapChatLogEvent ev
                )
        ChangeVisible filter ->
            ( ChatBox { model | targetChat = Maybe.map ChatId <| String.toInt filter }
            , Cmd.none
            , []
            )
        OnViewUser -> ( ChatBox model, Cmd.none, [ ViewUser ] )
        OnViewVotes -> ( ChatBox model, Cmd.none, [ ViewVotes ] )

divk : Html msg -> Html msg
divk = div [] << List.singleton

divc : String -> Html msg -> Html msg
divc cl = div [ class cl ] << List.singleton

view : Data -> LangLocal -> ChatBox -> Html ChatBoxMsg
view data lang (ChatBox model) = divc "w-chat-box" <|
    div [] <| List.filterMap identity
        [ Maybe.map (viewStatus lang)
            <| getGame data model
        , Just <| divc "w-chat-log-box" <| divk <|
            Html.map WrapChatLog <| 
            lazy (ChatLog.view data lang) model.chatLog
        , Just <| divc "w-chat-selector-box" <| divk <|
            div [ class "w-chat-selector" ]
            [ div [] <| List.singleton <| select
                [ class "w-chat-filter"
                , title "chat filter" 
                , on "change" <| 
                    Json.map ChangeFilter Html.Events.targetValue
                ] 
                <| (::) (node "option" 
                    [ value "" 
                    , selected <| model.selected == Nothing
                    ] [ text <| getSingle lang ["ui", "no-filter"] ]) 
                <| List.map
                    (\(id,key) ->
                        node "option" 
                            [ value <| String.fromInt <| Types.chatId id 
                            , selected <| model.selected == Just id
                            ] 
                            [ text <| getChatName lang key ]
                    )
                <| UnionDict.toList
                <| UnionDict.map (expand (.chatRoom << .chat))
                <| UnionDict.unsafen ChatId Types.chatId
                <| Maybe.withDefault (UnionDict.include Dict.empty)
                <| Maybe.map .chats 
                <| UnionDict.get model.ownGroupId
                <| UnionDict.unsafen GroupId Types.groupId 
                <| data.game.groups
            , div [] <| List.singleton <| select
                [ class "w-chat-target"
                , title "target chat" 
                , on "change" <| 
                    Json.map ChangeVisible Html.Events.targetValue
                ] 
                <| List.map
                    (\(id,chat) ->
                        node "option"
                            [ value <| String.fromInt <| Types.chatId id 
                            , selected <| Just id == model.targetChat
                            ] 
                            [ text <| getChatName lang chat.chatRoom 
                            ]
                    )
                <| List.filter (Tuple.second >> .permission >> .write)
                <| UnionDict.toList
                <| UnionDict.map (expand .chat)
                <| UnionDict.unsafen ChatId Types.chatId
                <| Maybe.withDefault (UnionDict.include Dict.empty)
                <| Maybe.map .chats 
                <| UnionDict.get model.ownGroupId
                <| UnionDict.unsafen GroupId Types.groupId 
                <| data.game.groups
            , div 
                [ class "w-chat-view-user" 
                , onClick OnViewUser
                ]
                [ text <| getSingle lang [ "ui", "view-user"] ]
            , div 
                [ class "w-chat-view-votes" 
                , onClick OnViewVotes
                ]
                [ text <| getSingle lang [ "ui", "view-votes"] ]
            ]
        , if canViewChatInsertBox data model
            then Just 
                <| divc "w-chat-insert-box" 
                <| divk 
                <| Html.map WrapChatInsertBox 
                <| ChatInsertBox.view lang model.insertBox
            else Nothing
        ]

viewStatus : LangLocal -> Game -> Html ChatBoxMsg
viewStatus lang game = divc "w-chat-phase-status" <| divk <| div []
    [ divk <| text <| getSingle lang [ "ui", "day-count" ]
    , divk <| text <| String.fromInt <| game.day
    , divk <| text <| getSingle lang [ "ui", "day-time" ]
    , divk <| text <| getSingle lang 
        [ "phase-time", String.left 1 game.phase ]
    , divk <| text <| getSingle lang [ "ui", "day-phase" ]
    , divk <| text <| getSingle lang [ "phase", game.phase ]
    ]


canViewChatInsertBox : Data -> ChatBoxInfo -> Bool
canViewChatInsertBox data info = case info.targetChat of
    Nothing -> False
    Just id -> getChatData data info id
        |> Maybe.map (.chat >> .permission >> .write)
        |> Maybe.withDefault False

getChatData : Data -> ChatBoxInfo -> ChatId -> Maybe Data.ChatData 
getChatData data info id = getChatDatas data info 
    |> UnionDict.get id

getChatDatas : Data -> ChatBoxInfo -> UnionDict Int ChatId Data.ChatData
getChatDatas data info = data.game.groups
    |> UnionDict.unsafen GroupId Types.groupId 
    |> UnionDict.get info.ownGroupId
    |> Maybe.map .chats 
    |> Maybe.withDefault (UnionDict.include Dict.empty)
    |> UnionDict.unsafen ChatId Types.chatId 

getGame : Data -> ChatBoxInfo -> Maybe Game
getGame data info = data.game.groups
    |> UnionDict.unsafen GroupId Types.groupId
    |> UnionDict.get info.ownGroupId
    |> Maybe.map .group
    |> Maybe.andThen .currentGame

expand : (a -> b) -> c -> a -> b
expand f a b = f b

handle : ChatBoxInfo -> List EventMsg -> (ChatBoxInfo, Cmd ChatBoxMsg, List ChatBoxEvent)
handle cinfo =  List.foldr
        (\msg (info, cmds, events) -> case msg of
            SendEvent text -> case info.targetChat of 
                Nothing -> (info, cmds, events)
                Just id ->
                    ( info
                    , cmds
                    , (Send 
                        <| ReqControl 
                        <| PostChat id text
                        ) :: events
                    )
        )
        (cinfo, [], [])
    >> \(a, b, c) -> (a, Cmd.batch b, c)
