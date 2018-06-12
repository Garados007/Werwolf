module Game.Lobby.ManageGroups exposing
    ( ManageGroups
    , ManageGroupsMsg
        ( SetConfig
        , SetGroups
        , SetUsers
        , SetOwnId
        )
    , ManageGroupsEvent (..)
    , ManageGroupsDef
    , manageGroupsModule
    )
    
import ModuleConfig as MC exposing (..)

import Game.Configuration exposing (..)
import Game.Utils.Dates exposing (convert)
import Game.Utils.Language exposing (..)
import Config exposing (..)
import Game.Lobby.ModalWindow exposing (modal)
import Game.Types.Types exposing (..)
import Game.Utils.UserLookup as UserLookup exposing (UserLookup)

import Html exposing (Html,div,text,a,img,input)
import Html.Attributes exposing (class,attribute,href,value,src)
import Html.Events exposing (onClick)
import Dict exposing (Dict)

type ManageGroups = ManageGroups ManageGroupsInfo

type alias ManageGroupsInfo =
    { config : LangConfiguration
    , groups : Dict Int Group
    , users : UserLookup
    , viewUser : Dict Int Bool
    , ownUser : Maybe Int
    }

type ManageGroupsMsg
    -- public Methods
    = SetConfig LangConfiguration
    | SetGroups (Dict Int Group)
    | SetUsers UserLookup
    | SetOwnId Int
    -- private Methods
    | OnClose
    | ToggleUser Int
    | OnFocus Int
    | OnLeave Int

type ManageGroupsEvent
    = Close
    | Focus Int
    | Leave Int

type alias ManageGroupsDef a = ModuleConfig ManageGroups ManageGroupsMsg
    () ManageGroupsEvent a

manageGroupsModule : (ManageGroupsEvent -> List a) ->
    (ManageGroupsDef a, Cmd ManageGroupsMsg, List a)
manageGroupsModule event = createModule
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }
    event ()

init : () -> (ManageGroups, Cmd ManageGroupsMsg, List a)
init () =
    ( ManageGroups
        { config = LangConfiguration empty <|
            createLocal (newGlobal lang_backup) Nothing
        , groups = Dict.empty
        , users = UserLookup.empty
        , viewUser = Dict.empty
        , ownUser = Nothing
        }
    , Cmd.none
    , []
    )

update : ManageGroupsDef a -> ManageGroupsMsg -> ManageGroups -> (ManageGroups, Cmd ManageGroupsMsg, List a)
update def msg (ManageGroups model) = case msg of
    SetConfig config ->
        ( ManageGroups { model | config = config }
        , Cmd.none
        , []
        )
    SetGroups groups ->
        ( ManageGroups { model | groups = groups }
        , Cmd.none
        , []
        )
    SetUsers users ->
        ( ManageGroups { model | users = users }
        , Cmd.none
        , []
        )
    SetOwnId id ->
        ( ManageGroups { model | ownUser = Just id }
        , Cmd.none
        , []
        )
    OnClose ->
        ( ManageGroups model
        , Cmd.none
        , event def Close
        )
    ToggleUser group ->
        ( ManageGroups
            { model
            | viewUser = case Dict.get group model.viewUser of
                Just m -> Dict.insert group (not m) model.viewUser
                Nothing -> Dict.insert group True model.viewUser
            }
        , Cmd.none
        , []
        )
    OnFocus group ->
        ( ManageGroups model
        , Cmd.none
        , event def <| Focus group
        )
    OnLeave group ->
        ( ManageGroups model
        , Cmd.none
        , event def <| Leave group)

view : ManageGroups -> Html ManageGroupsMsg
view (ManageGroups model) = 
    modal OnClose (getSingle model.config.lang ["lobby", "manage-groups" ]) <|
        div [ class "w-managegroup-box" ] <|
            List.map (viewGroup model) <|
            Dict.values model.groups

single : ManageGroupsInfo -> String -> String
single info key = getSingle info.config.lang [ "lobby", key ]

divs : Html msg -> Html msg
divs = div [] << List.singleton

user : ManageGroupsInfo -> Int -> String
user info u = case UserLookup.getSingleUser u info.users of
    Nothing -> (++) "User #" <| toString u
    Just u -> u.name

time : ManageGroupsInfo -> Int -> String
time info = convert info.config.conf.manageGroupsDateFormat << toFloat << (*) 1000

formatKey : String -> String
formatKey key =
    let ml : List Char -> List (List Char)
        ml = \list ->
            if list == []
            then []
            else (List.take 4 list) :: (ml <| List.drop 4 list)
    in String.fromList <| List.concat <|
        List.intersperse [' '] <| ml <| String.toList key

viewGroup : ManageGroupsInfo -> Group -> Html ManageGroupsMsg
viewGroup info group = div [ class "w-managegroup-group" ]
    [ div [ class "w-managegroup-title" ]
        [ text group.name ]
    , div [ class "w-managegroup-info" ]
        [ div []
            [ divs <| text <| single info "mg-construct-date"
            , divs <| text <| time info group.created
            ]
        , div []
            [ divs <| text <| single info "mg-constructor" 
            , divs <| text <| user info group.creator
            ]
        , div []
            [ divs <| text <| single info "mg-last-date"
            , divs <| text <| case group.lastTime of
                Just t -> time info t
                Nothing -> single info "mg-never"
            ]
        , div []
            [ divs <| text <| single info "mg-leader"
            , divs <| text <| user info group.leader
            ]
        , div []
            [ divs <| text <| single info "mg-current-game"
            , divs <| text <| case group.currentGame of
                Nothing -> single info "mg-no-game"
                Just game ->
                    if game.finished == Nothing
                    then time info game.started
                    else single info "mg-no-game"
            ]
        , div []
            [ divs <| text <| single info "mg-member"
            , divs <| text <| toString <| List.length <| UserLookup.getGroupUser group.id info.users
            ]
        , div []
            [ divs <| text <| single info "mg-enter-key"
            , div [ class "w-managegroup-password" ]
                [ text <| formatKey group.enterKey ]
            ]
        ]
    , div [ class "w-managegroup-buttons" ]
        [ div 
            [ class "w-managegroup-button" 
            , onClick (OnFocus group.id)
            ]
            [ text <| single info "mg-focus-group" ]
        , div 
            [ class "w-managegroup-button" 
            , onClick (ToggleUser group.id)
            ]
            [ text <| single info <| 
                if Maybe.withDefault False <| Dict.get group.id info.viewUser
                then "mg-hide-user"
                else "mg-view-user" 
            ]
        , if canLeave info group
            then div
                [ class "w-managegroup-button"
                , onClick (OnLeave group.id) 
                ]
                [ text <| single info "mg-leave-group" ]
            else text ""
        ]
    , if Maybe.withDefault False <| Dict.get group.id info.viewUser
        then div [ class "w-managegroup-users" ] <|
            List.map
                (\user ->
                    div [ class "w-managegroup-user" ]
                        [ divs <| img
                            [ src <| "https://www.gravatar.com/avatar/" ++
                                user.gravatar ++ 
                                "?d=identicon"
                                -- "?d=monsterid"
                                -- "?d=wavatar"
                                -- "?d=robohash"]
                            ] []
                        , divs <| text user.name
                        ]
                )
            <| UserLookup.getGroupUser group.id info.users
        else text ""
    ]

canLeave : ManageGroupsInfo -> Group -> Bool
canLeave info group =
    if group.currentGame /= Nothing
    then False
    else if Just group.leader /= info.ownUser
        then True
        else (>) 2 <| List.length <| 
            UserLookup.getGroupUser group.id info.users

subscriptions : ManageGroups -> Sub ManageGroupsMsg
subscriptions (ManageGroups model) =
    Sub.none