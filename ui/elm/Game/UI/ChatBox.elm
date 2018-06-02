module Game.UI.ChatBox exposing
    ( ChatBox
    , ChatBoxMsg
        ( AddChats
        , SetUser
        , SetRooms
        , SetConfig
        , SetGame
        )
    , ChatBoxEvent (..)
    , ChatBoxDef
    , chatBoxModule
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
import Game.Utils.Network exposing (Request)
import Game.Types.Request exposing (..)
import Game.Configuration exposing (..)
import Game.Utils.Language exposing (..)

import Html exposing (Html,div,select,option,node,text)
import Html.Attributes exposing (class,title,value,attribute)
import Html.Events exposing (on,onClick)
import Html.Lazy exposing (lazy)
import Dict exposing (Dict)
import Time exposing (second)
import Json.Decode as Json

type ChatBox = ChatBox ChatBoxInfo

type alias ChatBoxInfo =
    { config : LangConfiguration
    , chatLog : ChatLog
    , insertBox : ChatInsertBoxDef EventMsg
    , user : Dict UserId String
    , rooms : Dict ChatId Chat
    , selected : Maybe ChatId
    , targetChat : Maybe ChatId
    , game: Maybe Game
    }

type ChatBoxMsg
    -- public methods
    = AddChats (List ChatEntry)
    | SetUser (Dict UserId String)
    | SetRooms (Dict ChatId Chat)
    | SetConfig LangConfiguration
    | SetGame Game
    -- Wrapped
    | WrapChatLog ChatLog.Msg
    | WrapChatInsertBox ChatInsertBox.Msg
    -- private
    | ChangeFilter String
    | ChangeVisible String
    | OnViewUser
    | OnViewVotes

type EventMsg
    = SendText String

type ChatBoxEvent
    = ViewUser
    | ViewVotes
    | Send Request

type alias ChatBoxDef a b = ModuleConfig ChatBox ChatBoxMsg 
    (LangConfiguration, a) ChatBoxEvent b

chatBoxModule : (ChatBoxEvent -> List b) -> (LangConfiguration, a)  -> (ChatBoxDef a b, Cmd ChatBoxMsg, List b)
chatBoxModule = createModule
    { init = init
    , view = view
    , update = update
    , subscriptions = \_ -> Sub.none
    }

init : (LangConfiguration, a) -> (ChatBox, Cmd ChatBoxMsg, List b)
init (config, token) =
    let
        cl = ChatLog.init <| 
            (++) "chat-log-" <| toString token
        (cb, cbCmd, cbList) = chatInsertBoxModule handleChatInsertBox config
        info = ChatBoxInfo 
            config
            cl 
            cb
            Dict.empty Dict.empty
            Nothing Nothing Nothing
        (ninfo, moreCmd, pt) = handleOwn Nothing info cbList
    in
        ( ChatBox ninfo
        , Cmd.batch
            [ Cmd.map WrapChatInsertBox cbCmd
            , moreCmd
            ]
        , pt
        )

update : ChatBoxDef a b -> ChatBoxMsg -> ChatBox -> (ChatBox, Cmd ChatBoxMsg, List b)
update def msg (ChatBox model) =
    case msg of
        WrapChatLog wmsg ->
            let (wm, wcmd) = ChatLog.update 
                    wmsg model.chatLog
            in  ( ChatBox { model | chatLog = wm}
                , Cmd.map WrapChatLog wcmd
                , []
                )
        WrapChatInsertBox wmsg -> 
            let (wm, wcmd, wt) = MC.update model.insertBox wmsg
                (tm, task, tpm) = handleOwn (Just def) 
                    { model | insertBox = wm } wt
            in  ( ChatBox tm
                , Cmd.batch
                    [ task
                    , Cmd.map WrapChatInsertBox wcmd
                    ]
                , tpm
                )
        AddChats chats ->
            let
                (nm, cmds) = addAllChats model model.chatLog chats
            in (ChatBox {model | chatLog = nm}, Cmd.batch cmds, [])
        SetUser user ->
            let cu = Dict.toList user |> List.filterMap
                    (\(id,u) ->
                        case Dict.get id model.user of
                            Nothing -> Just <| UpdateUser id u
                            Just du ->
                                if du == u
                                then Just <| UpdateUser id u
                                else Nothing
                    )
                (nu, wcmd) = updateAll ChatLog.update model.chatLog cu
            in  (ChatBox { model | user = user, chatLog = nu}
                , Cmd.batch <| List.map (Cmd.map WrapChatLog) wcmd
                , []
                )
        SetRooms rooms ->
            let cr = Dict.values rooms |> List.filter 
                    (\r ->
                        case Dict.get r.id model.rooms of
                            Nothing -> True
                            Just dr -> dr /= r
                    ) |>
                    List.map (\r -> UpdateChat r.id r.chatRoom)
                (nr, wcmd) = updateAll ChatLog.update model.chatLog cr
                newModel = { model | rooms = rooms, chatLog = nr }
            in  (ChatBox { newModel | targetChat = getBestChatId newModel }
                , Cmd.batch <| List.map (Cmd.map WrapChatLog) wcmd
                , []
                )
        SetConfig config ->
            let (wm, wcmd, wt) = MC.update model.insertBox 
                    (ChatInsertBox.UpdateConfig config)
                (tm, task, tpm) = handleOwn (Just def) 
                    { model | config = config, insertBox = wm } wt
            in  (ChatBox tm
                , task
                , tpm
                )
        SetGame game ->
            (ChatBox { model | game = Just game }, Cmd.none, [])
        ChangeFilter filter ->
            let
                filt = Result.toMaybe <| String.toInt filter
                (wm, wcmd) = ChatLog.update (UpdateFilter filt) model.chatLog
            in  ( ChatBox { model | selected = filt, chatLog = wm }
                , Cmd.map WrapChatLog wcmd
                , []
                )
        ChangeVisible filter ->
            case String.toInt filter of
                Ok id ->
                    ( ChatBox { model | targetChat = Just id}, Cmd.none, [])
                Err _ ->
                    ( ChatBox { model | targetChat = Nothing }, Cmd.none, [])
        OnViewUser -> ( ChatBox model, Cmd.none, MC.event def ViewUser)
        OnViewVotes -> ( ChatBox model, Cmd.none, MC.event def ViewVotes)

divk : Html msg -> Html msg
divk = div [] << List.singleton

divc : String -> Html msg -> Html msg
divc cl = div [ class cl ] << List.singleton

single : ChatBoxInfo -> List String -> String
single info = getSingle info.config.lang

view : ChatBox -> Html ChatBoxMsg
view (ChatBox model) = divc "w-chat-box" <|
    div [] <| List.filterMap identity
        [ Maybe.map (viewStatus model.config.lang) model.game
        , Just <| divc "w-chat-log-box" <| divk <|
            Html.map WrapChatLog <| 
            lazy (ChatLog.view model.config) model.chatLog
        , Just <| divc "w-chat-selector-box" <| divk <|
            div [ class "w-chat-selector" ]
            [ div [] <| List.singleton <| select
                [ class "w-chat-filter"
                , title "chat filter" 
                , on "change" <| 
                    Json.map ChangeFilter Html.Events.targetValue
                ] <|
                (::) (node "option" [ value "" ] [ text <| single model ["ui", "no-filter"] ]) <|
                    List.map
                        (\(id,key) ->
                            node "option" [ value <| toString id ] 
                                [ text <| getChatName model.config.lang key ]
                        )
                        <| Dict.toList <| Dict.map (expand .chatRoom) model.rooms
            , div [] <| List.singleton <| select
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
                            <| [ text <| getChatName model.config.lang chat.chatRoom ]
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
                [ text <| single model [ "ui", "view-user"] ]
            , div 
                [ class "w-chat-view-votes" 
                , onClick OnViewVotes
                ]
                [ text <| single model [ "ui", "view-votes"] ]
            ]
        , if canViewChatInsertBox model
            then Just <| divc "w-chat-insert-box" <| divk <|
                Html.map WrapChatInsertBox <|
                MC.view model.insertBox
            else Nothing
        ]

viewStatus : LangLocal -> Game -> Html ChatBoxMsg
viewStatus lang game = divc "w-chat-phase-status" <| divk <| div []
    [ divk <| text <| getSingle lang [ "ui", "day-count" ]
    , divk <| text <| toString <| game.day
    , divk <| text <| getSingle lang [ "ui", "day-time" ]
    , divk <| text <| getSingle lang 
        [ "phase-time", String.left 1 game.phase ]
    , divk <| text <| getSingle lang [ "ui", "day-phase" ]
    , divk <| text <| getSingle lang [ "phase", game.phase ]
    ]

updateAll : (a -> b -> (b, Cmd a)) -> b -> List a -> (b, List (Cmd a))
updateAll f model tasks = case tasks of
    [] -> (model, [])
    t :: ts ->
        let
            (nm, ncmd) = f t model
            (tm, tcmd) = updateAll f nm ts
        in (tm, ncmd :: tcmd)

addAllChats : ChatBoxInfo -> ChatLog -> List ChatEntry -> (ChatLog, List (Cmd ChatBoxMsg))
addAllChats info log chats = 
    (\(cl,mes) -> (cl, List.map (Cmd.map WrapChatLog) mes)) <|
        updateAll ChatLog.update log <| List.map 
            (\c -> Add <| PostTile <| ChatPostTile
                (case Dict.get c.user info.user of
                    Just name -> name
                    Nothing -> "User #" ++ (toString c.user)
                )
                c.user
                ((toFloat c.sendDate) * second)
                (case Dict.get c.chat info.rooms of
                    Just room -> room.chatRoom
                    Nothing -> "Room #" ++ (toString c.chat)
                )
                c.chat
                c.text
                (decodeSpecial c.text)
                c.id
            )
            chats

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

getSendChatId : ChatBoxInfo -> Int
getSendChatId info =
    case info.targetChat of
        Just id -> id
        Nothing -> Debug.log "ChatBox:getSendChatId:no-chat-found" 0

getBestChatId : ChatBoxInfo -> Maybe ChatId
getBestChatId info =
    let
        (isOldGood,bid) = case info.targetChat of
            Nothing -> (False,0)
            Just id -> case Dict.get id info.rooms of
                Nothing -> (False,id)
                Just chat -> (chat.permission.write,id)
    in if isOldGood
        then Just bid
        else
            let chats = Dict.values info.rooms |>
                    List.filter (.permission >> .write)
            in case chats of
                [] -> Nothing
                c :: cs -> Just c.id
        
expand : (a -> b) -> c -> a -> b
expand f a b = f b

handleChatInsertBox : ChatInsertBox.EventMsg -> List EventMsg
handleChatInsertBox msg =
    case msg of
        SendEvent text -> [ SendText text ]

handleOwn : Maybe (ChatBoxDef a b) -> ChatBoxInfo -> List EventMsg -> (ChatBoxInfo, Cmd ChatBoxMsg, List b)
handleOwn mdef info list = 
    let (ninfo, ncmd, npr) = changeWithAll3
            (\info msg -> case msg of
                SendText text -> case mdef of
                    Nothing -> ( info, Cmd.none, [])
                    Just def ->
                        ( info
                        , Cmd.none
                        , MC.event def <| Send <| RespControl <|
                            PostChat (getSendChatId info) text
                        )
            )
            info
            list
    in (ninfo, Cmd.batch ncmd, List.concat npr)
