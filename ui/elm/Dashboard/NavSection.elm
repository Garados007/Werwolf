module Dashboard.NavSection exposing (..)

import Dashboard.Environment exposing (..)
import Dashboard.Util.Html exposing (..)
import Html exposing (Html,div,text)
import Html.Attributes as HA exposing (class)
import Html.Events as HE
import Set exposing (Set)
import Dict
import Browser
import Config exposing (uri_host,uri_path)
import List

main : Platform.Program () NavSection NavSectionMsg
main = Browser.element
    { init = \() -> (init, Cmd.none)
    , view = \model -> div []
        [ view [ Dashboard.Environment.test ] model
        , dashboardStylesheet "nav-section"
        ]
    , update = \msg model ->
        update [ Dashboard.Environment.test ] msg model 
        |> \(a, b, e) -> 
            let d_ = 
                    if List.isEmpty e
                    then e 
                    else Debug.log "event" e                
            in (a, b)
    , subscriptions = \_ -> Sub.none
    }

type alias NavSection =
    { openedNodes : Set (List String)

    }

type NavSectionMsg 
    = NoOp
    | ChangeOpen (List String) Bool 
    | CallEvent (List NavSectionEvent)

type NavSectionEvent
    = OpenRoleCode String String
    | OpenRoleInfo String String

init : NavSection
init = 
    { openedNodes = Set.empty 
    }

view : List Environment -> NavSection -> Html NavSectionMsg
view envs nav = Html.nav
    [ class "navigation-box" ]
    [ div [ class "navigation-add-module" ]
        [ text "Add Module" ]
    , Html.ul [ class "navigation-content" ]
        <| List.map (viewEnvironment nav)
        <| envs
    ]

viewNode : NavSection -> String -> List String -> NavSectionMsg 
    -> List (Html NavSectionMsg) -> Html NavSectionMsg
viewNode nav title path msg subNodes = Html.li 
    [ HA.classList 
        [ Tuple.pair "navigation-node" True
        , Tuple.pair "opened" 
            <| Set.member path 
            <| nav.openedNodes
        , Tuple.pair "empty"
            <| List.isEmpty subNodes
        ]
    ]
    [ div [ class "header" ]
        [ div 
            [ class "opener"
            , HE.onClick
                <| ChangeOpen path 
                <| not 
                <| Set.member path 
                <| nav.openedNodes
            ] 
            [ div [] [] ]
        , div 
            [ HA.classList 
                [ Tuple.pair "title" True 
                , Tuple.pair "link"
                    <| msg /= NoOp
                ] 
            , HE.onClick msg
            ]
            [ text title ]
        ]
    , Html.ul [ class "subnodes" ]
        subNodes
    ]

viewEnvironment : NavSection -> Environment -> Html NavSectionMsg
viewEnvironment nav env = viewNode 
    nav
    env.moduleName
    [ env.moduleName ]
    NoOp 
    <|  let button : String -> NavSectionMsg 
                -> List (Html NavSectionMsg) -> Html NavSectionMsg
            button title = viewNode nav title [ env.moduleName, title ]
        in  [ button "Info" NoOp []
            , button "Roles" NoOp 
                <| (::) (viewNode
                        nav 
                        "add Role"
                        [ env.moduleName, "Roles", "add Role" ]
                        NoOp 
                        []
                    )
                <| List.map 
                    (\k -> viewRoleList
                        nav 
                        [ env.moduleName, "Roles" ]
                        (CallEvent [ OpenRoleInfo env.moduleName k ])
                        k
                    )
                <| Dict.keys env.roles
            , button "Logic" NoOp 
                <| List.map 
                    (\k -> viewNode
                        nav 
                        k
                        [ env.moduleName, "Logic", k ]
                        (CallEvent
                            <| List.singleton
                            <| OpenRoleCode env.moduleName k 
                        )
                        []
                    )
                <| Dict.keys env.roles
            , button "Language" NoOp []
            , button "Test" NoOp []
            ]

viewRoleList : NavSection -> List String -> NavSectionMsg -> String -> Html NavSectionMsg
viewRoleList nav root msg key = viewNode
    nav 
    key 
    (root ++ [ key ])
    msg 
    []

update : List Environment -> NavSectionMsg -> NavSection 
    -> (NavSection, Cmd NavSectionMsg, List NavSectionEvent)
update envs msg nav = case msg of 
    NoOp -> tripel nav Cmd.none []
    ChangeOpen path open ->
        (   { nav 
            | openedNodes =
                if open 
                then Set.insert path nav.openedNodes
                else Set.remove path nav.openedNodes
            }
        , Cmd.none 
        , []
        )
    CallEvent list -> tripel nav Cmd.none list

tripel : a -> b -> c -> (a, b, c)
tripel a b c = (a, b, c)
