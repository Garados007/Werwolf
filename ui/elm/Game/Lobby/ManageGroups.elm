module Game.Lobby.ManageGroups exposing
    ( ManageGroups
    , ManageGroupsMsg
    , ManageGroupsEvent (..)
    , init
    , view
    , update
    )

import Game.Configuration exposing (..)
import Game.Utils.Dates exposing (convert)
import Game.Utils.Language exposing (..)
import Config exposing (..)
import Game.Lobby.ModalWindow exposing (modal)
import Game.Types.Types as Types exposing (..)
import Game.Utils.UserLookup as UserLookup exposing (UserLookup)
import Game.Data as Data exposing (..)
import DataDiff.Path as Diff exposing (DetectorPath, Path (..))
import DataDiff.Ex exposing (SingleActionEx (..), ModActionEx (..))
import UnionDict exposing (UnionDict, SafeDict)

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
    { viewUser : SafeDict Int GroupId Bool
    , banOpened : SafeDict Int GroupId Bool
    }

type ManageGroupsMsg
    -- public Methods
    -- private Methods
    = OnClose
    | ToggleUser GroupId
    | OnFocus GroupId
    | OnLeave GroupId
    | OnDoBan GroupId UserId
    | OnToggleBan GroupId
    | Refresh GroupId
    | OnUnban GroupId UserId

type ManageGroupsEvent
    = Close
    | Focus GroupId
    | Leave GroupId
    | DoBan GroupId UserId
    | FetchBans GroupId
    | Unban GroupId UserId

init : ManageGroups
init = ManageGroups
    { viewUser = UnionDict.include Dict.empty
    , banOpened = UnionDict.include Dict.empty
    }

update : ManageGroupsMsg -> ManageGroups -> (ManageGroups, Cmd ManageGroupsMsg, List ManageGroupsEvent)
update msg (ManageGroups model) = case msg of
    OnClose ->
        ( ManageGroups model
        , Cmd.none
        , [ Close ]
        )
    ToggleUser group ->
        ( ManageGroups
            { model
            | viewUser =
                let dict : UnionDict Int GroupId Bool
                    dict = model.viewUser
                        |> UnionDict.unsafen GroupId Types.groupId
                    value : Bool 
                    value = dict 
                        |> UnionDict.get group
                        |> Maybe.withDefault False 
                        |> not
                in UnionDict.insert group value dict 
                    |> UnionDict.safen
            }
        , Cmd.none
        , []
        )
    OnFocus group ->
        ( ManageGroups model
        , Cmd.none
        , [ Focus group ]
        )
    OnLeave group ->
        ( ManageGroups model
        , Cmd.none
        , [ Leave group ]
        )
    OnDoBan group user ->
        ( ManageGroups model
        , Cmd.none
        , [ DoBan group user ]
        )
    OnToggleBan group ->
        let dict : UnionDict Int GroupId Bool 
            dict = UnionDict.unsafen GroupId Types.groupId model.banOpened
            opened : Maybe Bool
            opened =  UnionDict.get group dict
        in  ( ManageGroups
                { model
                | banOpened = UnionDict.safen
                    <| UnionDict.insert 
                        group
                        (not <| Maybe.withDefault False opened)
                        dict
                }
            , Cmd.none
            , if opened /= Just True
                then [ FetchBans group ]
                else []
            )
    Refresh group ->
        ( ManageGroups model
        , Cmd.none
        , [ FetchBans group ]
        )
    OnUnban group user ->
        ( ManageGroups model
        , Cmd.none
        , [ Unban group user ]
        )

isDelete : BanInfo -> Posix -> Bool
isDelete ban now = case ban.endDate of
    Nothing -> False
    Just d -> Time.posixToMillis d <= Time.posixToMillis now

view : Data -> LangLocal -> ManageGroups -> Html ManageGroupsMsg
view data lang (ManageGroups model) = modal
        OnClose (getSingle lang ["lobby", "manage-groups" ]) 
    <| div [ class "w-managegroup-box" ] 
    <| List.map (viewGroup data lang model) 
    <| List.map .group
    <| Dict.values
    <| UnionDict.extract
    <| data.game.groups

single : LangLocal -> String -> String
single lang key = getSingle lang [ "lobby", "manage-group", key ]

divs : Html msg -> Html msg
divs = div [] << List.singleton

getUser : Data -> UserId -> String
getUser data user = 
    case UserLookup.getSingleUser 
        (Types.userId user) 
        data.game.users 
    of
        Nothing -> (++) "User #" 
            <| String.fromInt
            <| Types.userId user
        Just u -> u.name

getTime : Data -> Posix -> String
getTime data time = convert 
    data.config.manageGroupsDateFormat 
    time
    data.time.zone

formatKey : String -> String
formatKey key =
    let ml : List Char -> List (List Char)
        ml list =
            if list == []
            then []
            else (List.take 4 list) :: (ml <| List.drop 4 list)
    in String.fromList <| List.concat <|
        List.intersperse [' '] <| ml <| String.toList key

viewGroup : Data -> LangLocal -> ManageGroupsInfo -> Group -> Html ManageGroupsMsg
viewGroup data lang info group = div [ class "w-managegroup-group" ]
    [ div [ class "w-managegroup-title" ]
        [ text group.name ]
    , div [ class "w-managegroup-info" ]
        [ div []
            [ divs <| text <| single lang "construct-date"
            , divs <| text <| getTime data group.created
            ]
        , div []
            [ divs <| text <| single lang "constructor" 
            , divs <| text <| getUser data group.creator
            ]
        , div []
            [ divs <| text <| single lang "last-date"
            , divs <| text <| case group.lastTime of
                Just t -> getTime data t
                Nothing -> single lang "never"
            ]
        , div []
            [ divs <| text <| single lang "leader"
            , divs <| text <| getUser data group.leader
            ]
        , div []
            [ divs <| text <| single lang "current-game"
            , divs <| text <| case group.currentGame of
                Nothing -> single lang "no-game"
                Just game ->
                    if game.finished == Nothing
                    then getTime data game.started
                    else single lang "no-game"
            ]
        , div []
            [ divs <| text <| single lang "member"
            , divs <| text <| String.fromInt 
                <| List.length 
                <| UserLookup.getGroupUser 
                    (Types.groupId group.id) data.game.users
            ]
        , div []
            [ divs <| text <| single lang "enter-key"
            , div [ class "w-managegroup-password" ]
                [ text <| formatKey group.enterKey ]
            ]
        ]
    , div [ class "w-managegroup-buttons" ]
        [ div 
            [ class "w-managegroup-button" 
            , onClick (OnFocus group.id)
            ]
            [ text <| single lang "focus-group" ]
        , div 
            [ class "w-managegroup-button" 
            , onClick (ToggleUser group.id)
            ]
            [ text <| single lang <| 
                if Maybe.withDefault False 
                    <| UnionDict.get group.id 
                    <| UnionDict.unsafen GroupId Types.groupId
                    <| info.viewUser
                then "hide-user"
                else "view-user" 
            ]
        , div
            [ class "w-managegroup-button"
            , onClick (OnToggleBan group.id)
            ]
            [ text <| single lang <|
                if Maybe.withDefault False 
                    <| UnionDict.get group.id 
                    <| UnionDict.unsafen GroupId Types.groupId
                    <| info.banOpened
                then "hide-ban"
                else "view-ban" 
            ]
        , if (==) (Just True) 
            <| UnionDict.get group.id 
            <| UnionDict.unsafen GroupId Types.groupId
            <| info.banOpened 
            then div
                [ class "w-managegroup-button"
                , onClick (Refresh group.id)
                ]
                [ text <| single lang "refresh-ban"]
            else text ""
        , if canLeave data group
            then div
                [ class "w-managegroup-button"
                , onClick (OnLeave group.id) 
                ]
                [ text <| single lang "leave-group" ]
            else text ""
        ]
    , if Maybe.withDefault False 
        <| UnionDict.get group.id 
        <| UnionDict.unsafen GroupId Types.groupId
        <| info.viewUser
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
                        , if canBan data group user
                            then div 
                                [ class "w-managegroup-ban" 
                                , attribute "title" <| single lang "do-ban"
                                , onClick (OnDoBan group.id user.userId)
                                ]
                                [ text "X" ]
                            else text ""
                        ]
                )
            <| UserLookup.getGroupUser (Types.groupId group.id) data.game.users
        else text ""
    , if Maybe.withDefault False 
        <| UnionDict.get group.id 
        <| UnionDict.unsafen GroupId Types.groupId
        <| info.banOpened
        then div [ class "w-managegroup-banned" ] <|
            let bans = List.map (viewBan data lang group) 
                    <| List.filter ((==) group.id << .group)
                    <| data.game.bans
            in if List.isEmpty bans
                then [ div [ class "w-managegroup-nobans"]
                        [ text <| single lang "no-bans" ]
                    ]
                else bans
        else text ""
    ]

viewBan : Data -> LangLocal -> Group -> BanInfo -> Html ManageGroupsMsg
viewBan data lang group ban = 
    let buser = UserLookup.getSingleUser (Types.userId ban.user) data.game.users
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
                    [ divs <| text <| getUser data ban.user 
                    , case data.game.ownId of
                        Nothing -> text ""
                        Just id ->
                            if (id == ban.spoker) || (id == group.leader)
                            then div 
                                [ class "w-managegroup-unban" 
                                , onClick (OnUnban ban.group ban.user)
                                , attribute "title" <|
                                    single lang "revoke"
                                ]
                                [ text "X" ]
                            else text ""
                    ]
                , div [ class "w-managegroup-ban-spoker" ]
                    [ divs <| text <| single lang "spoker"
                    , divs <| text <| getUser data ban.spoker
                    ]
                ]
            ]
        , div [ class "w-managegroup-ban-timing" ]
            [ div [ class "w-managegroup-ban-timeinfo" ]
                [ divs <| text <| getTime data ban.startDate
                , divs <| text "-"
                , case ban.endDate of
                    Just d -> divs <| text <| getTime data d
                    Nothing -> divs <| text <| 
                       String.fromChar <| Char.fromCode 8734
                ]
            , if ban.endDate == Nothing then text "" else div
                [ class "w-managegroup-ban-timebar" ]
                [ div
                    [ class "w-managegroup-ban-timefill"
                    , style "width"
                        <| (String.fromFloat <| timePos data.time.now ban) ++ "%"
                    ] []
                ]
            ]
        ]

timePos : Posix -> BanInfo -> Float
timePos now ban = case ban.endDate of
    Just end ->
        let st = toFloat <| Time.posixToMillis ban.startDate
            et = toFloat <| Time.posixToMillis end
            nt = toFloat <| Time.posixToMillis now
        in max 0 <| min 100 <| 100 * (nt - st) / (et - st)
    Nothing -> 0


canLeave : Data -> Group -> Bool
canLeave data group =
    if group.currentGame /= Nothing
    then False
    else if Just group.leader /= data.game.ownId
        then True
        else (>) 2 <| List.length <| 
            UserLookup.getGroupUser (Types.groupId group.id) data.game.users

canBan : Data -> Group -> UserStat -> Bool
canBan data group user =
    (Just user.userId /= data.game.ownId) &&
    (Just group.leader == data.game.ownId)
