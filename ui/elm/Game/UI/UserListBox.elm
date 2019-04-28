module Game.UI.UserListBox exposing
    ( UserListBox
    , UserListBoxMsg
    , UserListEvent (..)
    , init
    , view
    , update
    )

import Game.Types.Types as Types exposing (..)
import Game.Utils.Dates exposing (convert)
import Game.Configuration exposing (..)
import Game.Utils.Language exposing (..)
import Game.Data as Data exposing (Data)
import UnionDict exposing (UnionDict)

import Html exposing (Html,div,text,node,img)
import Html.Attributes exposing (class,value,src,title,selected)
import Html.Events exposing (on,onClick)
import Dict exposing (Dict)
import Json.Decode as Json
import Config exposing (..)
import Time exposing (Posix, Zone)
import Time.Extra exposing (diff, Interval (..))
import Task

type UserListBox = UserListBox UserListBoxInfo

type alias UserListBoxInfo =
    { groupId : GroupId
    , filter: Maybe String
    }

type UserListBoxMsg
    -- public methods
    -- public event
    = OnCloseBox
    -- private methods
    | ChangeFilter String

type UserListEvent 
    = CloseBox

init : GroupId -> UserListBox
init group = UserListBox 
    { groupId = group
    , filter = Nothing
    }

view : Data -> LangLocal -> UserListBox -> Html UserListBoxMsg
view data lang (UserListBox model) =
    div [ class "w-user-roles-box" ]
        [ viewBoxHeader lang model
        , viewChatSelector data lang model
        , div []
            ( List.map 
                (div [ class "w-user-box-outer" ] 
                    << List.singleton
                )
                <| List.map 
                    (viewUser data lang model
                        <| getRuleset data model.groupId
                    ) 
                <| filterUser data model
            )
        ]

getRuleset : Data -> GroupId -> Maybe String 
getRuleset data groupId =  data
    |> Data.getGroup groupId
    |> Maybe.andThen (.group >> .currentGame)
    |> Maybe.map .ruleset

filterUser : Data -> UserListBoxInfo -> List User
filterUser data info = List.filter
    (\user -> case info.filter of
        Nothing -> True
        Just filter ->
            case find filter 
                <| List.map .chat 
                <| UnionDict.values 
                <| getChats data info 
            of
                Nothing -> True
                Just chat -> case user.player of
                    Nothing -> False
                    Just player ->
                        List.member player.id chat.permission.player
    )
    <| getUser data info

getChats : Data -> UserListBoxInfo -> UnionDict Int ChatId Data.ChatData
getChats data info = data.game.groups
    |> UnionDict.unsafen GroupId Types.groupId 
    |> UnionDict.get info.groupId
    |> Maybe.map .chats
    |> Maybe.withDefault (UnionDict.include Dict.empty)
    |> UnionDict.unsafen ChatId Types.chatId

getUser : Data -> UserListBoxInfo -> List User 
getUser data info = data.game.groups 
    |> UnionDict.unsafen GroupId Types.groupId 
    |> UnionDict.get info.groupId
    |> Maybe.map .user 
    |> Maybe.withDefault []

find : String -> List Chat -> Maybe Chat
find key list =
    case list of
        [] -> Nothing
        c :: cs ->
            if c.chatRoom == key
            then Just c
            else find key cs
    
viewChatSelector : Data -> LangLocal -> UserListBoxInfo -> Html UserListBoxMsg
viewChatSelector data lang info =
    if UnionDict.isEmpty <| getChats data info
    then div [] []
    else div [ class "w-user-select-chat" ]
        [ node "select" 
            [ on "change" <| 
                Json.map ChangeFilter Html.Events.targetValue
            ] <|
            (::) (node "option" 
                [ value "" 
                , selected <| info.filter == Nothing
                ] 
                [ text <| getSingle lang ["ui", "filter-all"] ]) <|
                List.map
                    (\key ->
                        node "option" 
                            [ value key 
                            , selected <| Just key == info.filter
                            ] 
                            [ text<| getChatName lang key ]
                    )
                    <| List.map (.chat >> .chatRoom)
                    <| UnionDict.values 
                    <| getChats data info

        ]

viewUser : Data -> LangLocal -> UserListBoxInfo -> Maybe String -> User -> Html UserListBoxMsg
viewUser data lang info ruleset user =
    div [ class "w-user-box" ]
        [ div [ class "w-user-icon-area" ]
            [ div [ class "w-user-icon" ]
                [ img
                    [ src <| "https://www.gravatar.com/avatar/" ++
                        user.stats.gravatar ++ 
                        "?d=identicon"
                        -- "?d=monsterid"
                        -- "?d=wavatar"
                        -- "?d=robohash"
                    , class "w-user-icon-gravatar"
                    ] []
                ]
            , div [ class "w-user-last-online" ]
                [ text <| getTime data lang user.stats.lastOnline 
                ]
            ]
        , div [ class "w-user-info-area" ]
            [ div [ class "w-user-name" ]
                [ text <| user.stats.name ]
            , div [ class "w-user-roles" ] <| 
                let additionalRoles : List (Html msg)
                    additionalRoles = List.filterMap 
                        (Maybe.map 
                            <| div [ class "w-user-role w-user-rolespecial" ] 
                            << List.singleton
                        )
                        [ case user.player of
                            Just player ->
                                if player.alive
                                then Nothing
                                else Just <| div 
                                    [ class "w-user-special-death"
                                    , title <| getSingle lang [ "ui", "player-death" ]
                                    ] []
                            Nothing -> Nothing
                        , if data.game.ownId == Just user.user
                            then Just <| div 
                                [ class "w-user-special-ownuser" 
                                , title <| getSingle lang [ "ui", "player-own" ]
                                ] []
                            else Nothing
                        ]
                    showRoles : Role -> List (Html msg)
                    showRoles = \role -> case ruleset of
                        Nothing -> []
                        Just rs ->
                            [ img
                                [ src <| uri_host ++ uri_path ++
                                    "ui/img/roles/" ++ rs ++
                                    "/" ++ role.roleKey ++ ".svg"
                                ] []
                            ] 
                    flip : (a -> b -> c) -> b -> a -> c
                    flip f b a = f a b
                in flip (++) additionalRoles <| case user.player of
                    Nothing -> []
                    Just player -> List.map
                        (\role -> div 
                            [ class <| "w-user-role w-user-role-" 
                                ++ role.roleKey
                            , Html.Attributes.attribute 
                                "data-role" role.roleKey
                            , title <| getSingle lang [ "roles", role.roleKey]
                            ]
                            <| showRoles role
                        )
                        player.roles
            ]
        ]

viewBoxHeader : LangLocal -> UserListBoxInfo -> Html UserListBoxMsg
viewBoxHeader lang info = div [ class "w-box-header"]
    [ div [ class "w-box-header-title" ]
        [ text <| getSingle lang
            [ "ui", "user-header" ]
        ]
    , div [ class "w-box-header-close", onClick OnCloseBox ]
        [ text "X" ]
    ]

getTime : Data -> LangLocal -> Posix -> String
getTime data lang time =
    let dif = diff Second Time.utc time data.time.now 
    in
        if dif < 30
        then getSingle lang ["ui", "online"]
        else if dif < 60 * 45
        then "-" ++ (String.fromInt <| dif // 60000) ++ "min"
        else if dif < 60 * 60 * 16
        then convert data.config.profileTimeFormat time data.time.zone
        else convert data.config.profileDateFormat time data.time.zone

update : UserListBoxMsg -> UserListBox -> (UserListBox, Cmd UserListBoxMsg, List UserListEvent)
update msg (UserListBox model) = case msg of
    ChangeFilter filter ->
        ( UserListBox { model | filter = Just filter }
        , Cmd.none
        , []
        )
    OnCloseBox -> 
        ( UserListBox model
        , Cmd.none
        , [ CloseBox ]
        )
