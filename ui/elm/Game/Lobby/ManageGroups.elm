module Game.Lobby.ManageGroups exposing
    ( ManageGroups
    , ManageGroupsMsg
    , ManageGroupsEvent (..)
    , ManageGroupsDef
    , manageGroupsModule
    , msgSetConfig
    , msgSetGroups
    , msgSetUsers
    , msgSetOwnId
    , msgAddBan
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
import Html.Attributes exposing (class,attribute,href,value,src,style)
import Html.Events exposing (onClick)
import Dict exposing (Dict)
import Char
import Time exposing (Posix, Zone)
import Time.Extra
import Task

type ManageGroups = ManageGroups ManageGroupsInfo

type alias ManageGroupsInfo =
    { config : LangConfiguration
    , groups : Dict Int Group
    , users : UserLookup
    , viewUser : Dict Int Bool
    , ownUser : Maybe Int
    , bans : Dict Int (Dict Int BanInfo)
    , banOpened : Dict Int Bool
    , now : Posix
    , zone : Zone
    }

type ManageGroupsMsg
    -- public Methods
    = SetConfig LangConfiguration
    | SetGroups (Dict Int Group)
    | SetUsers UserLookup
    | SetOwnId Int
    | AddBan BanInfo
    -- private Methods
    | OnClose
    | ToggleUser Int
    | OnFocus Int
    | OnLeave Int
    | OnDoBan Int Int
    | OnToggleBan Int
    | NewTime Posix
    | NewZone Zone
    | Refresh Int
    | OnUnban Int Int

type ManageGroupsEvent
    = Close
    | Focus Int
    | Leave Int
    | DoBan Int Int
    | FetchBans Int
    | Unban Int Int

type alias ManageGroupsDef a = ModuleConfig ManageGroups ManageGroupsMsg
    () ManageGroupsEvent a

msgSetConfig : LangConfiguration -> ManageGroupsMsg
msgSetConfig = SetConfig

msgSetGroups : Dict Int Group -> ManageGroupsMsg
msgSetGroups = SetGroups

msgSetUsers : UserLookup -> ManageGroupsMsg
msgSetUsers = SetUsers

msgSetOwnId : Int -> ManageGroupsMsg
msgSetOwnId = SetOwnId

msgAddBan : BanInfo -> ManageGroupsMsg
msgAddBan = AddBan

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
        , bans = Dict.empty
        , banOpened = Dict.empty
        , now = Time.millisToPosix 0
        , zone = Time.utc
        }
    , Task.perform NewZone <| Time.here
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
        ( ManageGroups 
            { model 
            | groups = groups 
            , bans = Dict.merge
                (\_ _ d -> d)
                (\k _ v d -> Dict.insert k v d)
                (\_ _ d -> d)
                groups
                model.bans
                Dict.empty
            , banOpened = Dict.merge
                (\_ _ d -> d)
                (\k _ v d -> Dict.insert k v d)
                (\_ _ d -> d)
                groups
                model.banOpened
                Dict.empty
            }
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
    AddBan ban ->
        ( ManageGroups
            { model
            | bans = if isDelete ban model.now
                then case Dict.get ban.group model.bans of
                    Just d -> 
                        let nd = Dict.remove ban.user d
                        in if Dict.isEmpty nd
                            then Dict.remove ban.group model.bans
                            else Dict.insert ban.group nd model.bans
                    Nothing -> model.bans
                else case Dict.get ban.group model.bans of
                    Just d -> Dict.insert ban.group
                        (Dict.insert ban.user ban d) model.bans
                    Nothing -> Dict.insert ban.group
                        (Dict.insert ban.user ban Dict.empty) model.bans
            }
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
        , event def <| Leave group
        )
    OnDoBan group user ->
        ( ManageGroups model
        , Cmd.none
        , event def <| DoBan group user
        )
    OnToggleBan group ->
        let old = Dict.get group model.banOpened
        in  ( ManageGroups
                { model
                | banOpened = Dict.insert 
                    group
                    (not <| Maybe.withDefault False old)
                    model.banOpened
                , bans = if old == Just True
                    then Dict.remove group model.bans
                    else model.bans
                }
            , Cmd.none
            , if old /= Just True
                then MC.event def <| FetchBans group
                else []
            )
    Refresh group ->
        ( ManageGroups
            { model
            | bans = Dict.remove group model.bans
            }
        , Cmd.none
        , MC.event def <| FetchBans group
        )
    NewTime time ->
        ( ManageGroups 
            { model
            | now = time 
            , bans = Dict.map
                ( \_ -> Dict.filter 
                    <| \_ b -> not 
                    <| isDelete b model.now
                )
                model.bans
            }
        , Cmd.none
        , []
        )
    NewZone zone->
        ( ManageGroups
            { model
            | zone = zone
            }
        , Cmd.none
        , []
        )
    OnUnban group user ->
        ( ManageGroups model
        , Cmd.none
        , MC.event def <| Unban group user
        )

isDelete : BanInfo -> Posix -> Bool
isDelete ban now = case ban.endDate of
    Nothing -> False
    Just d -> d * 1000 <= Time.posixToMillis now

view : ManageGroups -> Html ManageGroupsMsg
view (ManageGroups model) = 
    modal OnClose (getSingle model.config.lang ["lobby", "manage-groups" ]) <|
        div [ class "w-managegroup-box" ] <|
            List.map (viewGroup model) <|
            Dict.values model.groups

single : ManageGroupsInfo -> String -> String
single info key = getSingle info.config.lang [ "lobby", "manage-group", key ]

divs : Html msg -> Html msg
divs = div [] << List.singleton

getUser : ManageGroupsInfo -> Int -> String
getUser info user = case UserLookup.getSingleUser user info.users of
    Nothing -> (++) "User #" <| String.fromInt user
    Just u -> u.name

getTime : ManageGroupsInfo -> Int -> String
getTime info time = convert 
    info.config.conf.manageGroupsDateFormat 
    (Time.millisToPosix <| time * 1000)
    info.zone

formatKey : String -> String
formatKey key =
    let ml : List Char -> List (List Char)
        ml list =
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
            [ divs <| text <| single info "construct-date"
            , divs <| text <| getTime info group.created
            ]
        , div []
            [ divs <| text <| single info "constructor" 
            , divs <| text <| getUser info group.creator
            ]
        , div []
            [ divs <| text <| single info "last-date"
            , divs <| text <| case group.lastTime of
                Just t -> getTime info t
                Nothing -> single info "never"
            ]
        , div []
            [ divs <| text <| single info "leader"
            , divs <| text <| getUser info group.leader
            ]
        , div []
            [ divs <| text <| single info "current-game"
            , divs <| text <| case group.currentGame of
                Nothing -> single info "no-game"
                Just game ->
                    if game.finished == Nothing
                    then getTime info game.started
                    else single info "no-game"
            ]
        , div []
            [ divs <| text <| single info "member"
            , divs <| text <| String.fromInt <| List.length <| UserLookup.getGroupUser group.id info.users
            ]
        , div []
            [ divs <| text <| single info "enter-key"
            , div [ class "w-managegroup-password" ]
                [ text <| formatKey group.enterKey ]
            ]
        ]
    , div [ class "w-managegroup-buttons" ]
        [ div 
            [ class "w-managegroup-button" 
            , onClick (OnFocus group.id)
            ]
            [ text <| single info "focus-group" ]
        , div 
            [ class "w-managegroup-button" 
            , onClick (ToggleUser group.id)
            ]
            [ text <| single info <| 
                if Maybe.withDefault False <| Dict.get group.id info.viewUser
                then "hide-user"
                else "view-user" 
            ]
        , div
            [ class "w-managegroup-button"
            , onClick (OnToggleBan group.id)
            ]
            [ text <| single info <|
                if Maybe.withDefault False <| Dict.get group.id info.banOpened
                then "hide-ban"
                else "view-ban" 
            ]
        , if Dict.get group.id info.banOpened == Just True
            then div
                [ class "w-managegroup-button"
                , onClick (Refresh group.id)
                ]
                [ text <| single info "refresh-ban"]
            else text ""
        , if canLeave info group
            then div
                [ class "w-managegroup-button"
                , onClick (OnLeave group.id) 
                ]
                [ text <| single info "leave-group" ]
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
                        , if canBan info group user
                            then div 
                                [ class "w-managegroup-ban" 
                                , attribute "title" <| single info "do-ban"
                                , onClick (OnDoBan group.id user.userId)
                                ]
                                [ text "X" ]
                            else text ""
                        ]
                )
            <| UserLookup.getGroupUser group.id info.users
        else text ""
    , if Maybe.withDefault False <| Dict.get group.id info.banOpened
        then div [ class "w-managegroup-banned" ] <|
            let bans = List.map (viewBan info group) <|
                    Dict.values <|
                    Maybe.withDefault Dict.empty <|
                    Dict.get group.id info.bans
            in if List.isEmpty bans
                then [ div [ class "w-managegroup-nobans"]
                        [ text <| single info "no-bans" ]
                    ]
                else bans
        else text ""
    ]

viewBan : ManageGroupsInfo -> Group -> BanInfo -> Html ManageGroupsMsg
viewBan info group ban = 
    let buser = UserLookup.getSingleUser ban.user info.users
    in div 
        [ class "w-managegroup-baninfo" 
        , attribute "title" ban.comment
        ]
        [ div [ class "w-managegroup-ban-details" ]
            [ div [ class "w-managegroup-ban-icon" ]
                [ img
                    [ src <| case buser of 
                        Just u -> "https://www.gravatar.com/avatar/" ++
                            u.gravatar ++ 
                            "?d=identicon"
                            -- "?d=monsterid"
                            -- "?d=wavatar"
                            -- "?d=robohash"
                        Nothing -> "https://www.gravatar.com/avatar/?d=mp"
                    ] []
                ]
            , div [ class "w-managegroup-ban-detaillist" ]
                [ div [ class "w-managegroup-ban-user" ]
                    [ divs <| text <| getUser info ban.user 
                    , case info.ownUser of
                        Nothing -> text ""
                        Just id ->
                            if (id == ban.spoker) || (id == group.leader)
                            then div 
                                [ class "w-managegroup-unban" 
                                , onClick (OnUnban ban.group ban.user)
                                , attribute "title" <|
                                    single info "revoke"
                                ]
                                [ text "X" ]
                            else text ""
                    ]
                , div [ class "w-managegroup-ban-spoker" ]
                    [ divs <| text <| single info "spoker"
                    , divs <| text <| getUser info ban.spoker
                    ]
                ]
            ]
        , div [ class "w-managegroup-ban-timing" ]
            [ div [ class "w-managegroup-ban-timeinfo" ]
                [ divs <| text <| getTime info ban.startDate
                , divs <| text "-"
                , case ban.endDate of
                    Just d -> divs <| text <| getTime info d
                    Nothing -> divs <| text <| 
                       String.fromChar <| Char.fromCode 8734
                ]
            , if ban.endDate == Nothing then text "" else div
                [ class "w-managegroup-ban-timebar" ]
                [ div
                    [ class "w-managegroup-ban-timefill"
                    , style "width"
                        <| (String.fromFloat <| timePos info.now ban) ++ "%"
                    ] []
                ]
            ]
        ]

timePos : Posix -> BanInfo -> Float
timePos now ban = case ban.endDate of
    Just end ->
        let st = (toFloat ban.startDate) * 1000
            et = (toFloat end) * 1000
            nt = toFloat <| Time.posixToMillis now
        in max 0 <| min 100 <| 100 * (nt - st) / (et - st)
    Nothing -> 0


canLeave : ManageGroupsInfo -> Group -> Bool
canLeave info group =
    if group.currentGame /= Nothing
    then False
    else if Just group.leader /= info.ownUser
        then True
        else (>) 2 <| List.length <| 
            UserLookup.getGroupUser group.id info.users

canBan : ManageGroupsInfo -> Group -> UserStat -> Bool
canBan info group user =
    (Just user.userId /= info.ownUser) &&
    (Just group.leader == info.ownUser)

subscriptions : ManageGroups -> Sub ManageGroupsMsg
subscriptions (ManageGroups model) =
    if model.now == Time.millisToPosix 0
    then Time.every 1000 NewTime
    else Time.every 60000 NewTime