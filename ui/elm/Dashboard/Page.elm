module Dashboard.Page exposing (..)

import Html exposing (Html, div, text)
import Html.Attributes as HA exposing (class)
import Html.Events as HE
import Set exposing (Set)
import Dict exposing (Dict)
import Config exposing (uri_host,uri_path)
import List.Extra as LE
import Browser
import Task

import Dashboard.Environment exposing (..)
import Dashboard.Editor as DEditor
import Dashboard.NavSection as DNav
import Dashboard.StatusBar as DStatus
import Dashboard.Editor.Logic exposing (CodeEnvironment)
import Dashboard.Util.Html exposing (..)
import Dashboard.Role.Info as DRoleInfo

main : Platform.Program () Model Msg 
main = Browser.element 
    { init = \() -> Tuple.pair init 
        <| Task.perform WrapNav 
        <| Task.succeed
        <| DNav.CallEvent
        <| List.singleton 
        <| DNav.OpenRoleInfo "Test Module" "role1"
    , view = view
    , update = update
    , subscriptions = subscriptions
    }

type alias Model =
    { viewMode : ViewMode
    , nav : DNav.NavSection
    , status : DStatus.StatusBar
    , env : List Environment
    , cachedCode : Dict String (Dict String CodeEnvironment)
    }

type Msg 
    = NoOp
    | WrapViewMode ViewMsg
    | WrapNav (DNav.NavSectionMsg)
    | WrapStatus (DStatus.StatusBarMsg)

type ViewMsg 
    = VMEditor DEditor.EditorMsg 
    | VMRoleInfo DRoleInfo.Msg

type ViewMode
    = ViewNone
    | ViewEditor String String DEditor.Editor
    | ViewRoleInfo String String DRoleInfo.RoleInfo

init : Model 
init =
    { viewMode = ViewNone 
    , nav = DNav.init
    , status = DStatus.init
    , env = [ test ]
    , cachedCode = Dict.empty
    }

view : Model -> Html Msg 
view model = div
    [ class "page-container" ]
    [ div [ class "page-main-container" ]
        [ Html.map WrapNav
            <| DNav.view model.env model.nav
        , div [ class "page-content" ]
            <| List.singleton
            <| viewViewMode model
        ]
    , Html.map WrapStatus 
        <| DStatus.view model.status
    , dashboardStylesheet "page"
    , dashboardStylesheet "editor-view"
    , dashboardStylesheet "nav-section"
    , dashboardStylesheet "status-bar"
    , dashboardStylesheet "role-info"
    ]

viewViewMode : Model -> Html Msg 
viewViewMode model = case model.viewMode of 
    ViewNone -> div [] []
    ViewEditor modul _ editor -> Html.map (WrapViewMode << VMEditor)
        <| case LE.find ((==) modul << .moduleName) model.env of
            Just env -> DEditor.view env editor 
            Nothing -> text ""
    ViewRoleInfo modul _ info -> Html.map (WrapViewMode << VMRoleInfo)
        <| case LE.find ((==) modul << .moduleName) model.env of 
            Just env -> DRoleInfo.view env info 
            Nothing -> text ""

update : Msg -> Model -> (Model, Cmd Msg)
update msg model = case msg of 
    NoOp -> (model, Cmd.none)
    WrapViewMode pmsg -> case (model.viewMode, pmsg) of 
        (ViewEditor modul key editor, VMEditor smsg) -> 
            case LE.find ((==) modul << .moduleName) model.env of
                Just env -> 
                    let (ne, ecmd, ee) = DEditor.update env smsg editor
                        (nmodel, tcmd) = perform
                            (\m t -> (m, Cmd.none, []))
                            model 
                            ee
                    in Tuple.pair 
                        { nmodel 
                        | viewMode = ViewEditor modul key ne
                        }
                        <| Cmd.batch [ Cmd.map (WrapViewMode << VMEditor) ecmd, tcmd ]
                Nothing -> (model, Cmd.none)
        (ViewRoleInfo modul key info, VMRoleInfo smsg) ->
            case LE.find ((==) modul << .moduleName) model.env of 
                Just env ->
                    let (ne, nenv, ev) = DRoleInfo.update env smsg info 
                        (nmodel, tcmd) = perform 
                            handleRoleInfo
                            { model | viewMode = ViewRoleInfo modul key ne }
                            ev 
                    in Tuple.pair 
                        { nmodel 
                        | env = List.map 
                            (\e -> 
                                if e.moduleName == nenv.moduleName
                                then nenv
                                else e
                            )
                            model.env
                        }
                        tcmd
                Nothing -> (model, Cmd.none)
        _ -> (model, Cmd.none)
    WrapNav smsg ->
        let (nn, ncmd, ne) = DNav.update model.env smsg model.nav
            (nmodel, tcmd) = perform
                handleNav
                { model | nav = nn }
                ne 
        in Tuple.pair 
            (backupData model.viewMode nmodel.viewMode nmodel)
            <| Cmd.batch [ Cmd.map WrapNav ncmd, tcmd ]
    WrapStatus smsg ->
        let (ns, scmd, se) = DStatus.update smsg model.status
            (nmodel, tcmd) = perform
                (\m t -> (m, Cmd.none, []))
                model 
                se 
        in Tuple.pair 
            { nmodel | status = ns }
            <| Cmd.batch [ Cmd.map WrapStatus scmd, tcmd ]

viewModeChanged : ViewMode -> ViewMode -> Bool 
viewModeChanged mode1 mode2 = case (mode1, mode2) of 
    (ViewNone, ViewNone) -> False 
    (ViewEditor a1 b1 _, ViewEditor a2 b2 _) -> a1 /= a2 || b1 /= b2 
    (ViewRoleInfo a1 b1 _, ViewRoleInfo a2 b2 _) -> a1 /= a2 || b1 /= b2 
    _ -> True

backupData : ViewMode -> ViewMode -> Model -> Model 
backupData old new model = 
    if viewModeChanged old new 
    then case old of 
        ViewNone -> model 
        ViewEditor modul role editor ->
            { model 
            | cachedCode = Dict.update modul 
                ( Maybe.withDefault Dict.empty 
                    >> Dict.insert role editor.code
                    >> Just 
                )
                model.cachedCode
            }
        ViewRoleInfo _ _ _ -> model 
    else model 

perform : (Model -> a -> (Model, Cmd Msg, List a)) -> Model -> List a
    -> (Model, Cmd Msg)
perform func model tasks = 
    let performUpdate : Model -> List (Cmd Msg) -> List a -> (Model, List (Cmd Msg))
        performUpdate m c t = case t of
            [] -> (m, c)
            t1::ts -> 
                let (rm, rc, rt) = func m t1
                in performUpdate rm (rc::c) (ts ++ rt)
    in Tuple.mapSecond Cmd.batch 
        <| performUpdate model [] tasks    

handleEditor : Model -> DEditor.EditorEvent -> (Model, Cmd Msg, List DEditor.EditorEvent)
handleEditor model event = case event of 
    DEditor.CodeChanged ce -> tripel
        { model 
        | cachedCode = case model.viewMode of 
            ViewEditor modul key _ -> Dict.update 
                modul 
                (Just 
                    << Dict.insert key ce
                    << Maybe.withDefault Dict.empty 
                )
                model.cachedCode
            _ -> model.cachedCode
        }
        Cmd.none 
        []

handleNav : Model -> DNav.NavSectionEvent -> (Model, Cmd Msg, List DNav.NavSectionEvent)
handleNav model event = case event of 
    DNav.OpenRoleCode modul key -> tripel 
        { model 
        | viewMode = ViewEditor modul key 
            <|  ( case Dict.get modul model.cachedCode
                    |> Maybe.andThen (Dict.get key)
                of  Just c -> DEditor.initCode c 
                    Nothing -> identity
                )
            <| DEditor.init key
        }
        Cmd.none 
        []
    DNav.OpenRoleInfo modul key -> tripel
        { model 
        | viewMode = ViewRoleInfo modul key 
            <| DRoleInfo.init key
        }
        Cmd.none 
        []

handleRoleInfo : Model -> DRoleInfo.Event -> (Model, Cmd Msg, List DRoleInfo.Event)
handleRoleInfo model event = case event of 
    DRoleInfo.CloseWindow -> tripel 
        { model 
        | viewMode = ViewNone
        }
        Cmd.none 
        []

subscriptions : Model -> Sub Msg 
subscriptions model = case model.viewMode of 
    ViewNone -> Sub.none 
    ViewEditor _ _ editor -> Sub.map (WrapViewMode << VMEditor)
        <| DEditor.subscriptions editor
    ViewRoleInfo _ _ _  -> Sub.none

tripel : a -> b -> c -> (a, b, c)
tripel a b c = (a, b, c)
