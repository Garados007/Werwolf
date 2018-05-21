module Game.UI.ChatBox exposing
    ( ChatBox
    , ChatBoxMsg
        ( SetChats
        , SetDateFormat
        , SetUser
        , SetRooms
        , Send
        )
    , init
    , update
    , view
    )

import ModuleConfig as MC exposing (..)

import Game.UI.ChatLog as ChatLog exposing (..)
import Game.UI.ChatPostTile as ChatPostTile exposing (..)
import Game.UI.ChatInsertBox as ChatInsertBox exposing (..)
import Game.Types.Types exposing (..)
import Game.Types.Request exposing (ChatId, UserId)
import Game.Utils.Dates exposing (DateTimeFormat(..))
import Game.Utils.Network exposing (Request)
import Game.Types.Request exposing (..)

import Html exposing (Html,div,select,option,node,text)
import Html.Attributes exposing (class,title,value,attribute)
import Html.Events exposing (on,onClick)
import Dict exposing (Dict)
import Time exposing (second)
import Json.Decode as Json
import Task

type ChatBox = ChatBox ChatBoxInfo

type alias ChatBoxInfo =
    { chatLog : ChatLog
    , insertBox : ChatInsertBoxDef EventMsg
    , chats : Dict ChatId (Dict Int ChatEntry)
    , user : Dict UserId String
    , rooms : Dict ChatId Chat
    , dateFormat : DateTimeFormat
    , selected : Maybe ChatId
    , targetChat : Maybe ChatId
    }

type ChatBoxMsg
    -- public methods
    = SetChats (Dict ChatId (Dict Int ChatEntry))
    | SetDateFormat DateTimeFormat
    | SetUser (Dict UserId String)
    | SetRooms (Dict ChatId Chat)
    -- public events
    | OnViewUser
    | OnViewVotes
    | Send Request
    -- Wrapped
    | WrapChatLog ChatLog.Msg
    | WrapChatInsertBox ChatInsertBox.Msg
    -- private
    | ChangeFilter String
    | ChangeVisible String

type EventMsg
    = SendText String

init : a -> (ChatBox, Cmd ChatBoxMsg)
init token =
    let
        cl = ChatLog.init <| 
            (++) "chat-log-" <| toString token
        (cb, cbCmd, cbList) = chatInsertBoxModule handleChatInsertBox
        moreCmd = handleOwn Nothing cbList
    in
        ( ChatBox <| ChatBoxInfo 
            cl 
            cb
            Dict.empty Dict.empty Dict.empty
            DD_MM_YYYY_H24_M_S
            Nothing Nothing
        , Cmd.batch
            [ Cmd.map WrapChatInsertBox cbCmd
            , moreCmd
            ]
        )

update : ChatBoxMsg -> ChatBox -> (ChatBox, Cmd ChatBoxMsg)
update msg (ChatBox model) =
    case msg of
        WrapChatLog wmsg ->
            let (wm, wcmd) = ChatLog.update 
                    wmsg model.chatLog
            in (ChatBox { model | chatLog = wm},
                Cmd.map WrapChatLog wcmd)
        WrapChatInsertBox wmsg -> 
            let (wm, wcmd, wt) = MC.update model.insertBox wmsg
                task = handleOwn (Just model) wt
            in  ( ChatBox { model | insertBox = wm }
                , Cmd.batch
                    [ task
                    , Cmd.map WrapChatInsertBox wcmd
                    ]
                )
        SetChats chats ->
            let nm = { model | chats = chats }
                (wm, wcmd) = ChatLog.update
                    ( Set <| List.map Tuple.second <|
                        getChats nm
                    )
                    model.chatLog
            in ( ChatBox { nm | chatLog = wm }
                , Cmd.map WrapChatLog wcmd)
        SetDateFormat format ->
            let nm = { model | dateFormat = format }
                (wm, wcmd) = ChatLog.update
                    ( Set <| List.map Tuple.second <|
                        getChats nm
                    )
                    model.chatLog
            in ( ChatBox { nm | chatLog = wm }
                , Cmd.map WrapChatLog wcmd)
        SetUser user ->
            let nm = { model | user = user }
                (wm, wcmd) = ChatLog.update
                    ( Set <| List.map Tuple.second <|
                        getChats nm
                    )
                    model.chatLog
            in ( ChatBox { nm | chatLog = wm }
                , Cmd.map WrapChatLog wcmd)
        SetRooms rooms ->
            let nm = { model | rooms = rooms }
                (wm, wcmd) = ChatLog.update
                    ( Set <| List.map Tuple.second <|
                        getChats nm
                    )
                    model.chatLog
            in ( ChatBox { nm | chatLog = wm }
                , Cmd.map WrapChatLog wcmd)
        ChangeFilter filter ->
            case String.toInt filter of
                Ok id ->
                    ( ChatBox { model | selected = Just id }, Cmd.none)
                Err _ ->
                    ( ChatBox { model | selected = Nothing }, Cmd.none)
        ChangeVisible filter ->
            case String.toInt filter of
                Ok id ->
                    ( ChatBox { model | targetChat = Just id}, Cmd.none)
                Err _ ->
                    ( ChatBox { model | targetChat = Nothing }, Cmd.none)
        OnViewUser -> ( ChatBox model, Cmd.none )
        OnViewVotes -> ( ChatBox model, Cmd.none )
        Send _ -> (ChatBox model, Cmd.none)

view : ChatBox -> Html ChatBoxMsg
view (ChatBox model) =
    div [ class "w-chat-box" ]
        [ Html.map WrapChatLog <|
            ChatLog.view model.chatLog
        , div [ class "w-chat-selector" ]
            [ select
                [ class "w-chat-filter"
                , title "chat filter" 
                , on "change" <| 
                    Json.map ChangeFilter Html.Events.targetValue
                ] <|
                (::) (node "option" [ value "" ] [ text "no filter" ]) <|
                    List.map
                        (\(id,key) ->
                            node "option" [ value <| toString id ] [ text key ]
                        )
                        <| Dict.toList <| Dict.map (expand .chatRoom) model.rooms
            ,  select
                [ class "w-chat-target"
                , title "target chat" 
                , on "change" <| 
                    Json.map ChangeVisible Html.Events.targetValue
                ] <|
                List.map
                    (\(id,chat) ->
                        node "option"
                            ( if Just id == model.targetChat
                                then 
                                    [ value <| toString id 
                                    , attribute "selected" "selected"
                                    ] 
                                else [ value <| toString id ] 
                            )
                            <| [ text chat.chatRoom ]
                    )
                    <| List.filter 
                        (\(id, chat) ->
                            chat.permission.write
                        )
                        <| Dict.toList model.rooms
            , div 
                [ class "w-chat-view-user" 
                , onClick OnViewUser
                ]
                [ text "view-user"]
            , div 
                [ class "w-chat-view-votes" 
                , onClick OnViewVotes
                ]
                [ text "view-votes"]
            ]
        , if canViewChatInsertBox model
            then Html.map WrapChatInsertBox <|
                MC.view model.insertBox
            else div [] []
        ]

canViewChatInsertBox : ChatBoxInfo -> Bool
canViewChatInsertBox info =
    case info.targetChat of
        Just id ->
            let
                chat : Maybe Chat
                chat = Dict.get id info.rooms
            in case chat of
                Nothing -> False
                Just c -> c.permission.write
        Nothing -> False
        -- Nothing -> Dict.values info.rooms
        --     |> List.any (.permission >> .write)


getSendChatId : ChatBoxInfo -> Int
getSendChatId info =
    case info.selected of
        Just id -> id
        Nothing -> Debug.log "ChatBox:getSendChatId:no-chat-found" 0
            -- let
            --     chats : List Chat
            --     chats = Dict.values info.rooms
            --         |> List.filter (.permission >> .write)
            --         |> List.filter (.permission >> .player >> List.isEmpty >> not)
            --         |> List.sortBy (.permission >> .player >> List.length)
            -- in case chats of
            --     [] -> Debug.log "ChatBox:getSendChatId:no-chat-found" 0
            --     c :: cs -> c.id

getChats : ChatBoxInfo -> List (Int, ChatTile)
getChats info =
    let
        func : Dict Int ChatEntry -> List (Int, ChatTile)
        func = getSingleChats info.dateFormat info.user <|
            Dict.map (expand .chatRoom) info.rooms
        chats = 
            case info.selected of
                Nothing ->
                    List.foldr List.append [] <|
                    List.map func <| Dict.values info.chats
                Just id ->
                    case Dict.get id info.chats of
                        Nothing -> []
                        Just chat -> func chat
        sorted = List.sortBy Tuple.first chats
    in sorted

expand : (a -> b) -> c -> a -> b
expand f a b = f b
        
getSingleChats : DateTimeFormat -> Dict UserId String -> Dict ChatId String -> Dict Int ChatEntry -> List (Int, ChatTile)
getSingleChats format user rooms dict =
    List.map
        (\(id,entry) ->
            ( id
            , PostTile <| ChatPostTile
                (case Dict.get entry.user user of
                    Just name -> name
                    Nothing -> "User #" ++ (toString entry.user)
                )
                ((toFloat entry.sendDate) * second)
                (case Dict.get entry.chat rooms of
                    Just name -> name
                    Nothing -> "Room #" ++ (toString entry.chat)
                )
                entry.text
                format
            )
        )
        <| Dict.toList dict

handleChatInsertBox : ChatInsertBox.EventMsg -> List EventMsg
handleChatInsertBox msg =
    case msg of
        SendEvent text -> [ SendText text ]

handleOwn : Maybe ChatBoxInfo -> List EventMsg -> Cmd ChatBoxMsg
handleOwn info = Cmd.batch << List.map
    (\msg -> case msg of
        SendText text -> case info of
            Nothing -> Cmd.none
            Just model -> Task.perform Send <| 
                Task.succeed <| RespControl <| 
                PostChat (getSendChatId model) text
                
    )