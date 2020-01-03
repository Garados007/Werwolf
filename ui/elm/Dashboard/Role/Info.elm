module Dashboard.Role.Info exposing (..)

import Html exposing (Html, div, text)
import Html.Attributes as HA exposing (class)
import Html.Events as HE
import Set exposing (Set)
import Dict exposing (Dict)
import Config exposing (uri_host,uri_path)
import List.Extra as LE
import Browser
import Json.Encode as JE
import Json.Decode as JD
import Regex

import Dashboard.Environment exposing (..)
import Dashboard.Util.Html exposing (..)
import Dashboard.Role.PermEditor as PermEditor exposing (cartesianPairs)

main : Platform.Program () TestModel Msg 
main = Browser.element
    { init = \() -> 
        ( TestModel (init "role1") Dashboard.Environment.test
        , Cmd.none
        )
    , view = \model -> div []
        [ view model.env model.info
        , dashboardStylesheet "perm-editor"
        ]
    , update = \msg model -> update model.env msg model.info
        |> \(m, e, _) -> (TestModel m e, Cmd.none)
    , subscriptions = always Sub.none
    }

type alias TestModel = 
    { info : RoleInfo
    , env : Environment
    }

type alias RoleInfo =
    { roleKey : String
    , perm : PermEditor.PermEditor
    , showCompareList : Bool
    , compareRole : Maybe String
    , cloneName : Maybe String
    , showDelete : Bool 
    }

type Msg 
    = None
    | WrapPermEditor PermEditor.Msg 
    | SetComment String
    | SetDefaultView String Bool
    | SetReqPhase String Bool 
    | SetOptTarget OptTarget Bool 
    | SetWinTogether String Bool 
    | SetCanVote (Maybe String) (Maybe String) Bool
    | ShowCompareList Bool
    | ShowCompare (Maybe String)
    | SetCloneName (Maybe String)
    | CloneRole String
    | SetShowDelete Bool 
    | DeleteThisRole

type OptTarget 
    = OTLeader 
    | OTCanStartNewRound
    | OTCanStartVotings
    | OTCanStopVotings

type Event 
    = CloseWindow

init : String -> RoleInfo 
init roleKey = 
    { roleKey = roleKey
    , perm = PermEditor.init
    , showCompareList = False
    , compareRole = Nothing
    , cloneName = Nothing
    , showDelete = False
    }

view : Environment -> RoleInfo -> Html Msg 
view environment info = case Dict.get info.roleKey environment.roles of 
    Nothing -> div [ class "loading" ]
        [ text "Loading data. Please wait a moment!" ]
    Just role -> div [ class "role-info" ]
        [ div [ class "title-bar" ]
            [ div [ class "title" ]
                [ text info.roleKey ]
            , div [ class "button-list" ]
                [ div 
                    [ class "button" 
                    , HE.onClick <| SetCloneName <| Just ""
                    ] 
                    [ text "Clone" ]
                , viewCloneName environment info role
                , div 
                    [ class "button" 
                    , HE.onClick <| SetShowDelete True
                    ] 
                    [ text "Delete" ]
                , viewDeleteBox environment info role
                -- , div [ class "button" ] [ text "Rename" ]
                , if info.compareRole == Nothing
                    then div 
                        [ class "button" 
                        , HE.onClick 
                            <| ShowCompareList True
                        ] 
                        [ text "Compare" ]
                    else div 
                        [ class "button" 
                        , HE.onClick <| ShowCompare Nothing
                        ]
                        [ text "Close Compare" ]
                , viewCompareList environment info role
                ]
            , case info.compareRole of 
                Nothing -> text ""
                Just key -> div [ class "title compare" ]
                    [ text key ]
            ]
        , div [ class "content" ]
            [ viewMainContent environment info role
            , case Maybe.andThen (\k -> Dict.get k environment.roles) info.compareRole of
                Nothing -> text ""
                Just crole -> viewMainContent environment info crole
            ]
        ]

viewCloneName : Environment -> RoleInfo -> RoleSetup -> Html Msg 
viewCloneName environment info role = case info.cloneName of 
    Nothing -> text ""
    Just name -> div [ class "clone-name-container menu" ]
        [ div 
            [ class "background"
            , HE.onClick <| SetCloneName Nothing
            ] []
        , div [ class "items can-middle" ]
            [ Html.h3 []
                [ text "Name for cloned role" ]
            , Html.p [ HA.style "min-width" "20em" ] 
                [ text "Only the configuration will be cloned. The code remains untouched." ]
            , Html.input 
                [ HA.type_ "text"
                , HA.value name
                , HE.onInput <| SetCloneName << Just 
                , onKeyEnter 
                    <|  if Regex.contains 
                                (Regex.fromString "^[a-zA-Z0-9_]{1,8}$"
                                    |> Maybe.withDefault Regex.never
                                )
                                name 
                            && not (Set.member name environment.keys.roleKeys)
                        then CloneRole name 
                        else None
                , HA.pattern "^[a-zA-Z0-9_]{1,8}$"
                ] []
            ,   if Regex.contains 
                    (Regex.fromString "^[a-zA-Z0-9_]{1,8}$"
                        |> Maybe.withDefault Regex.never
                    )
                    name
                then if Set.member name environment.keys.roleKeys
                    then Html.div [ class "error" ]
                        [ text "this name is already used" ]
                    else Html.button
                        [ class "button" 
                        , HE.onClick <| CloneRole name
                        ]
                        [ text "Create" ]
                else Html.div [ class "error" ]
                    [ text "The given name doesn't match the format "
                    , Html.span [ class "nobr" ] [ text "^[a-zA-Z0-9_]{1,8}$" ]
                    ]
            ]
        ]

viewDeleteBox : Environment -> RoleInfo -> RoleSetup -> Html Msg 
viewDeleteBox environment info role = 
    if info.showDelete 
    then div [ class "delete-box-container menu" ]
        [ div 
            [ class "background" 
            , HE.onClick <| SetShowDelete False 
            ] []
        , div [ class "items can-middle" ]
            [ Html.h3 []
                [ text "Do you realy want to delete this role?" ]
            , Html.p [] 
                [ text 
                    <| "No changes will be made to the logic code. "
                    ++ "All references will be unchanged."
                ]
            , Html.button
                [ class "button" 
                , HE.onClick DeleteThisRole
                ]
                [ text "Delete" ]
            ]
        ]
    else text ""

viewCompareList : Environment -> RoleInfo -> RoleSetup -> Html Msg 
viewCompareList environment info role = 
    if info.showCompareList 
    then div [ class "compare-list-container menu" ]
        [ div 
            [ class "background" 
            , HE.onClick <| ShowCompareList False
            ] []
        , div [ class "items" ]
            <| List.map 
                (\name -> div 
                    [ class "item button" 
                    , HE.onClick <| ShowCompare <| Just name 
                    ]
                    [ text name ]
                )
            <| List.filter ((/=) info.roleKey)
            <| Set.toList environment.keys.roleKeys
        ]
    else text ""

viewMainContent : Environment -> RoleInfo -> RoleSetup -> Html Msg 
viewMainContent environment info role = div 
    [ HA.classList
        [ Tuple.pair "main-content" True
        , Tuple.pair "dual" <| info.compareRole /= Nothing
        , Tuple.pair "second" <| info.roleKey /= role.key
        ] 
    ]
    [ Html.h2 [] [ text "Comment" ]
    , Html.textarea 
        [ class "comment" 
        , HE.onInput <|
            if info.roleKey /= role.key
            then always None
            else SetComment
        , HA.disabled <| info.roleKey /= role.key
        , HA.value role.comment
        ]
        []
    , Html.h2 [] [ text "Default view roles" ]
    , Html.p [] [ text "All roles that can be seen by this role by default" ]
    , viewInitCanView environment info role
    , Html.h2 [] [ text "Required Phases" ]
    , Html.p [] [ text "All required phases. Custom code will overwrite this behavior." ]
    , viewReqPhases environment info role
    , Html.h2 [] [ text "Permissions" ]
    , viewOpts environment info role
    , viewPermEditor environment info role
    , Html.h2 [] [ text "Win together" ]
    , Html.p [] 
        [ text 
            <| "if no fractions are used and custom code will call the "
            ++ "endgame routine, this matrix will be checked. This role "
            ++ "will win together with the role who raised this event. "
            ++ "Custom code will overwrite this behavior."
        ]
    , viewWinTogether environment info role
    , Html.h2 [] [ text "Can Vote" ]
    , Html.p []
        [ text 
            <| "Define if this role can vote in the specific voting by default. "
            ++ "Custom code will overwrite this behavior."
        ]
    , viewCanVote environment info role
    ]

viewInitCanView : Environment -> RoleInfo -> RoleSetup -> Html Msg 
viewInitCanView environment info role = div 
    [ class "init-can-view" ]
    <| List.map 
        (\key ->
            let active = Set.member key role.initCanView
            in Html.label 
                [ HA.classList
                    [ Tuple.pair "active" active ]
                ]
                [ Html.input 
                    [ HA.type_ "checkbox" 
                    , HA.checked active
                    , HE.onCheck <|
                        if info.roleKey /= role.key
                        then always None 
                        else SetDefaultView key
                    , HA.disabled <| info.roleKey /= role.key
                    ] []
                , Html.span [] [ text key ]
                ]
        )
    <| Set.toList environment.keys.roleKeys

viewReqPhases : Environment -> RoleInfo -> RoleSetup -> Html Msg 
viewReqPhases environment info role = div 
    [ class "req-phases" ]
    <| List.map 
        (\key -> 
            let day = String.left 1 key == "d"
                night = String.left 1 key == "n"
                title = if day || night then String.dropLeft 2 key else key 
                active = Set.member key role.reqPhases
            in Html.label 
                [ HA.classList 
                    [ Tuple.pair "active" active
                    , Tuple.pair "day" day
                    , Tuple.pair "night" night
                    ]
                , HA.title <|
                    if day 
                    then "day: " ++ title 
                    else if night 
                    then "night: " ++ title 
                    else title
                ]
                [ Html.input 
                    [ HA.type_ "checkbox"
                    , HA.checked active 
                    , HE.onCheck <|
                        if info.roleKey /= role.key
                        then always None 
                        else SetReqPhase key
                    , HA.disabled <| info.roleKey /= role.key
                    ] []
                , Html.span [] [ text title ]
                ]
        )
    <| Set.toList environment.keys.phaseKeys

viewOpts : Environment -> RoleInfo -> RoleSetup -> Html Msg 
viewOpts environment info role = div 
    [ class "opts" ]
    <| List.map 
        (\(target, opt, title) -> Html.label []
            [ Html.input 
                [ HA.type_ "checkbox"
                , HA.checked opt 
                , HE.onCheck <| 
                    if info.roleKey /= role.key
                    then always None 
                    else SetOptTarget target 
                , HA.disabled <| info.roleKey /= role.key
                ] []
            , Html.span [] [ text title ]
            ]
        )
        [ (OTLeader, role.leader, "Leader. Leader get full permissions of this group.")
        , (OTCanStartNewRound, role.canStartNewRound, "Can start new round")
        , (OTCanStartVotings, role.canStartVotings, "Can start votings")
        , (OTCanStopVotings, role.canStopVotings, "Can stop votings")
        ]

viewPermEditor : Environment -> RoleInfo -> RoleSetup -> Html Msg 
viewPermEditor environment info role = div
    [ class "wrap-container" ]
    <| List.singleton
    <| Html.map WrapPermEditor
    <| PermEditor.view 
        { editor = info.perm 
        , data = role.permissions
        , phases = environment.keys.phaseKeys
        , chats = environment.keys.chatKeys
        , readonly = info.roleKey /= role.key
        }

viewWinTogether : Environment -> RoleInfo -> RoleSetup -> Html Msg 
viewWinTogether environment info role = div 
    [ class "win-together" ]
    <| List.map 
        (\key ->
            let active = Set.member key role.winTogether
            in Html.label 
                [ HA.classList
                    [ Tuple.pair "active" <| active || role.key == key ]
                ]
                [ Html.input 
                    [ HA.type_ "checkbox" 
                    , HA.checked <| active || role.key == key
                    , HE.onCheck <|
                        if info.roleKey /= role.key || role.key == key
                        then always None 
                        else SetWinTogether key
                    , HA.disabled <| info.roleKey /= role.key
                        || role.key == key
                    ] []
                , Html.span [] [ text key ]
                ]
        )
    <| Set.toList environment.keys.roleKeys

viewCanVote : Environment -> RoleInfo -> RoleSetup -> Html Msg 
viewCanVote environment info role = 
    let viewRow : String -> (Maybe String -> Html Msg) -> Html Msg 
        viewRow title cellMaker = div [ class "row" ]
            <| (div [ class "cell title" ] [ text title ])
            :: (cellMaker Nothing)
            ::  ( List.map (cellMaker << Just)
                    <| Set.toList environment.keys.votingKeys
                )
        tryDefault : (() -> Maybe a) -> Maybe a -> Maybe a 
        tryDefault default value = case value of 
            Nothing -> default ()
            Just v -> Just v
        search : Maybe String -> Maybe String -> Maybe Bool 
        search chat voting = Maybe.map2 Tuple.pair chat voting 
            |> Maybe.andThen 
                (\(c, v) -> Dict.get c role.canVote
                    |> Maybe.map (Set.member v)
                )
            |> tryDefault 
                (\() -> Maybe.withDefault Nothing 
                    <| List.foldl 
                        (\(c, v) mo -> 
                            let new = role.canVote
                                    |> Dict.get c 
                                    |> Maybe.map (Set.member v)
                                    |> Maybe.withDefault False 
                            in case mo of 
                                Nothing -> Just <| Just new
                                Just o -> Just 
                                    ( if Just new == o then o else Nothing )
                        )
                        Nothing
                    <| cartesianPairs
                        ( case chat of 
                            Just c -> [ c ]
                            Nothing -> Set.toList environment.keys.chatKeys
                        )
                        ( case voting of 
                            Just v -> [ v ]
                            Nothing -> Set.toList environment.keys.votingKeys
                        )
                )
        viewCell : Maybe String -> Maybe String -> Html Msg 
        viewCell chat voting = 
            let active = search chat voting
            in div [ class "cell" ]
                <| List.singleton
                <| Html.input
                    [ HA.type_ "checkbox"
                    , HA.checked <| active == Just True 
                    , HA.property "indeterminate" 
                        <| JE.bool 
                        <| active == Nothing
                    , HA.title "can vote"
                    , HE.onCheck <| 
                        if info.roleKey /= role.key
                        then always None 
                        else SetCanVote chat voting
                    , HA.disabled <| info.roleKey /= role.key
                    ] []
    in div 
        [ class "can-vote" ]
        <| (viewRow "" <| div [ class "cell" ] << List.singleton << text << Maybe.withDefault "")
        :: (viewRow "" <| viewCell Nothing)
        ::  ( List.map
                (\key -> viewRow key <| viewCell (Just key))
                <| Set.toList environment.keys.chatKeys
            )

update : Environment -> Msg -> RoleInfo -> (RoleInfo, Environment, List Event)
update environment msg info = case Dict.get info.roleKey environment.roles of 
    Nothing -> tripel info environment []
    Just role -> case msg of 
        None -> tripel info environment []
        WrapPermEditor smsg -> 
            let result = PermEditor.update smsg 
                    -- read/write
                    { editor = info.perm 
                    , data = role.permissions
                    -- read only
                    , phases = environment.keys.phaseKeys
                    , chats = environment.keys.chatKeys
                    , readonly = False
                    }
            in  tripel 
                { info | perm = result.editor }
                { environment 
                | roles = Dict.insert info.roleKey 
                    { role | permissions = result.data }
                    environment.roles
                }
                []
        SetComment txt -> tripel info
            { environment 
            | roles = Dict.insert info.roleKey 
                { role | comment = txt }
                environment.roles
            }
            []
        SetDefaultView key value -> tripel info
            { environment 
            | roles = Dict.insert info.roleKey 
                { role 
                | initCanView =
                    (if value then Set.insert else Set.remove)
                    key 
                    role.initCanView
                }
                environment.roles
            }
            []
        SetReqPhase key value -> tripel info 
            { environment 
            | roles = Dict.insert info.roleKey
                { role 
                | reqPhases =
                    (if value then Set.insert else Set.remove)
                    key 
                    role.reqPhases
                }
                environment.roles
            }
            []
        SetOptTarget target value -> tripel info 
            { environment 
            | roles = Dict.insert info.roleKey
                ( case target of 
                    OTLeader -> { role | leader = value }
                    OTCanStartNewRound -> { role | canStartNewRound = value }
                    OTCanStartVotings -> { role | canStartVotings = value }
                    OTCanStopVotings -> { role | canStopVotings = value }
                )
                environment.roles
            }
            []
        SetWinTogether key value -> tripel info 
            { environment 
            | roles = Dict.insert info.roleKey 
                { role 
                | winTogether =
                    (if value then Set.insert else Set.remove)
                    key 
                    role.winTogether
                }
                environment.roles
            }
            []
        SetCanVote chat voting value -> tripel info 
            { environment 
            | roles = Dict.insert info.roleKey 
                { role 
                | canVote = List.foldl 
                        (\(c, v) -> Dict.update c 
                            (   if value 
                                then Maybe.withDefault Set.empty
                                    >> Set.insert v 
                                    >> Just 
                                else Maybe.andThen 
                                    ( Set.remove v
                                        >> \ns ->
                                            if Set.isEmpty ns 
                                            then Nothing
                                            else Just ns
                                    )
                            )
                        )
                        role.canVote
                    <| cartesianPairs
                        ( case chat of 
                            Just c -> [ c ]
                            Nothing -> Set.toList environment.keys.chatKeys
                        )
                        ( case voting of 
                            Just v -> [ v ]
                            Nothing -> Set.toList environment.keys.votingKeys
                        )
                }
                environment.roles 
            }
            []
        ShowCompareList value -> tripel 
            { info | showCompareList = value }
            environment
            []
        ShowCompare value -> tripel 
            { info 
            | showCompareList = False 
            , compareRole = value 
            }
            environment
            []
        SetCloneName value -> tripel 
            { info | cloneName = value }
            environment
            []
        CloneRole name -> tripel 
            { info | cloneName = Nothing }
            { environment 
            | roles = Dict.insert name 
                { role | key = name }
                environment.roles 
            , keys = environment.keys |> \keys -> 
                { keys 
                | roleKeys = Set.insert name keys.roleKeys
                }
            }
            []
        SetShowDelete value -> tripel 
            { info | showDelete = value }
            environment
            []
        DeleteThisRole -> tripel 
            { info | showDelete = False }
            { environment 
            | roles = Dict.remove info.roleKey environment.roles
            , keys = environment.keys |> \keys ->
                { keys 
                | roleKeys = Set.remove info.roleKey keys.roleKeys
                }
            }
            [ CloseWindow ]

tripel : a -> b -> c -> (a, b, c)
tripel a b c = (a, b, c)
