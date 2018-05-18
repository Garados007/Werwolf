module Game.UI.UserListBox exposing
    ( UserListBox
    , UserListBoxMsg
        ( UpdateUser
        , UpdateChats
        , UpdateRuleset
        )
    , init
    , view
    , update
    )

import Game.Types.Types exposing (..)
import Game.Types.Request exposing (ChatId)

import Html exposing (Html,div,text,node,img)
import Html.Attributes exposing (class,value,src,title)
import Html.Events exposing (on)
import Dict exposing (Dict)
import Json.Decode as Json
import Config exposing (..)

type UserListBox = UserListBox UserListBoxInfo

type alias UserListBoxInfo =
    { user : List User
    , chats : Dict ChatId Chat
    , filter: Maybe String
    , ruleset : Maybe String
    }

type UserListBoxMsg
    -- public methods
    = UpdateUser (List User)
    | UpdateChats (Dict ChatId Chat)
    | UpdateRuleset String
    -- private methods
    | ChangeFilter String

init : (UserListBox, Cmd UserListBoxMsg)
init = 
    (UserListBox <| 
        UserListBoxInfo [] Dict.empty Nothing
        Nothing
    , Cmd.none)

view : UserListBox -> Html UserListBoxMsg
view (UserListBox model) =
    div [ class "w-user-roles-box" ]
        [ div [ class "w-user-title" ]
            [ text "Nutzer" ]
        , viewChatSelector model
        , div []
            (List.map (viewUser model.ruleset) <| filterUser model)
        ]

filterUser : UserListBoxInfo -> List User
filterUser info =
    List.filter
        (\user -> case info.filter of
            Nothing -> True
            Just filter ->
                case find filter <| Dict.values info.chats of
                    Nothing -> True
                    Just chat -> case user.player of
                        Nothing -> False
                        Just player ->
                            List.member player.id chat.permission.player
        )
        info.user

find : String -> List Chat -> Maybe Chat
find key list =
    case list of
        [] -> Nothing
        c :: cs ->
            if c.chatRoom == key
            then Just c
            else find key cs
    
viewChatSelector : UserListBoxInfo -> Html UserListBoxMsg
viewChatSelector info =
    if Dict.isEmpty info.chats
    then div [] []
    else div [ class "w-user-select-chat" ]
        [ node "select" 
            [ on "change" <| 
                Json.map ChangeFilter Html.Events.targetValue
            ] <|
            (::) (node "option" [ value "" ] [ text "all" ]) <|
                List.map
                    (\key ->
                        node "option" [ value key ] [ text key ]
                    )
                    <| List.map .chatRoom
                    <| Dict.values info.chats

        ]

viewUser : Maybe String -> User -> Html UserListBoxMsg
viewUser ruleset user =
    div [ class "w-user-box" ]
        [ div [ class "w-user-icon-area" ]
            [ div [ class "w-user-icon" ]
                [ text "icon"
                ]
            , div [ class "w-user-last-online" ]
                [ text <| toString <| user.stats.lastOnline ]
            ]
        , div [ class "w-user-info-area" ]
            [ div [ class "w-user-name" ]
                [ text <| user.stats.name ]
            , div [ class "w-user-roles" ] <| case user.player of
                Nothing -> []
                Just player -> List.map
                    (\role -> div 
                        [ class <| "w-user-role w-user-role-" 
                            ++ role.roleKey
                        , Html.Attributes.attribute 
                            "data-role" role.roleKey
                        , title role.roleKey
                        ]
                        ( case ruleset of
                            Nothing -> []
                            Just rs ->
                                [ img
                                    [ src <| uri_host ++ uri_path ++
                                        "ui/img/roles/" ++ rs ++
                                        "/role-" ++ role.roleKey ++ ".png"
                                    ] []
                                ]
                        )
                    )
                    player.roles
            ]
        ]

update : UserListBoxMsg -> UserListBox -> (UserListBox, Cmd UserListBoxMsg)
update msg (UserListBox model) =
    case msg of
        UpdateUser user ->
            (UserListBox { model | user = user }, Cmd.none)
        UpdateChats chats ->
            (UserListBox { model | chats = chats }, Cmd.none)
        UpdateRuleset ruleset ->
            (UserListBox { model | ruleset = Just ruleset }, Cmd.none)
        ChangeFilter filter ->
            (UserListBox { model | filter = Just filter }, Cmd.none)
        
