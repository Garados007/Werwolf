module Game.UI.UserListBox exposing
    ( UserListBox
    , UserListBoxMsg
        ( UpdateUser
        , UpdateChats
        , UpdateRuleset
        , UpdateConfig
        )
    , init
    , view
    , update
    , subscriptions
    )

import Game.Types.Types exposing (..)
import Game.Types.Request exposing (ChatId)
import Game.Utils.Dates exposing (convert)
import Game.Configuration exposing (..)
import Game.Utils.Language exposing (..)

import Html exposing (Html,div,text,node,img)
import Html.Attributes exposing (class,value,src,title)
import Html.Events exposing (on)
import Dict exposing (Dict)
import Json.Decode as Json
import Config exposing (..)
import Time exposing (Time)

type UserListBox = UserListBox UserListBoxInfo

type alias UserListBoxInfo =
    { config : LangConfiguration
    , user : List User
    , chats : Dict ChatId Chat
    , filter: Maybe String
    , ruleset : Maybe String
    , time : Time
    }

type UserListBoxMsg
    -- public methods
    = UpdateUser (List User)
    | UpdateChats (Dict ChatId Chat)
    | UpdateRuleset String
    | UpdateConfig LangConfiguration
    -- private methods
    | ChangeFilter String
    | NewTime Time

single : UserListBoxInfo -> List String -> String
single info = getSingle info.config.lang

init : LangConfiguration -> (UserListBox, Cmd UserListBoxMsg)
init conf= 
    (UserListBox <| UserListBoxInfo 
        conf 
        [] 
        Dict.empty 
        Nothing
        Nothing 0
    , Cmd.none)

view : UserListBox -> Html UserListBoxMsg
view (UserListBox model) =
    div [ class "w-user-roles-box" ]
        [ div [ class "w-user-title" ]
            [ text <| single model ["ui", "user" ] ]
        , viewChatSelector model
        , div []
            (List.map (viewUser model model.ruleset) <| filterUser model)
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
            (::) (node "option" [ value "" ] 
                [ text <| single info ["ui", "filter-all"] ]) <|
                List.map
                    (\key ->
                        node "option" [ value key ] 
                            [ text<| getChatName info.config.lang key ]
                    )
                    <| List.map .chatRoom
                    <| Dict.values info.chats

        ]

viewUser : UserListBoxInfo -> Maybe String -> User -> Html UserListBoxMsg
viewUser info ruleset user =
    div [ class "w-user-box" ]
        [ div [ class "w-user-icon-area" ]
            [ div [ class "w-user-icon" ]
                [ text "icon"
                ]
            , div [ class "w-user-last-online" ]
                [ text <| getTime info user.stats.lastOnline ]
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
                        , title <| single info [ "roles", role.roleKey]
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

getTime : UserListBoxInfo -> Int -> String
getTime info time =
    let dif = info.time - (toFloat time * 1000)
    in
        if dif < Time.second * 30
        then getSingle info.config.lang ["ui", "online"]
        else if dif < Time.minute * 45
        then "-" ++ (toString <| round <| Time.inMinutes dif) ++ "min"
        else if dif < Time.hour * 16
        then convert info.config.conf.profileTimeFormat (toFloat time * 1000)
        else convert info.config.conf.profileDateFormat (toFloat time * 1000)

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
        NewTime time ->
            (UserListBox { model | time = time }, Cmd.none)
        UpdateConfig config ->
            (UserListBox { model | config = config }, Cmd.none)
        
subscriptions : UserListBox -> Sub UserListBoxMsg
subscriptions (UserListBox model) =
    Time.every Time.second NewTime