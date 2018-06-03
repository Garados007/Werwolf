module Game.Lobby.GameLobby exposing (..)

import ModuleConfig as MC exposing (..)

import Game.UI.GameView as GameView exposing (..)
import Game.Lobby.GameSelector as GameSelector exposing (..)
import Game.Utils.Network as Network exposing (..)
import Game.Types.Request exposing (..)
import Game.Types.Changes exposing (..)
import Game.Configuration exposing (..)
import Game.Utils.Language exposing (..)
import Game.Utils.LangLoader exposing (..)
import Config exposing (..)

import Html exposing (Html, div, node, program, text)
import Html.Attributes exposing (class, style, attribute)
import Dict exposing (Dict)

type GameLobby = GameLobby GameLobbyInfo

type alias GameLobbyInfo =
    { network : Network
    , games : Dict Int (GameViewDef EventMsg)
    , selector : GameSelectorDef EventMsg
    , config : Configuration
    , lang : LangGlobal
    , curGame : Maybe Int
    , ownId : Maybe Int
    , gameNames : Dict Int String
    }

type GameLobbyMsg
    = MNetwork NetworkMsg
    | MGameView Int GameViewMsg
    | MGameSelector GameSelectorMsg
    | MainLang String (Maybe String)
    | ModuleLang String String (Maybe String)

type EventMsg
    = Register Request
    | Unregister Request
    | Send Request
    | FetchRuleset String
    | EnterGroup Int
    | SetCurrent (Maybe Int)

main : Program Never GameLobby GameLobbyMsg
main = program
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }

handleGameView : Int -> GameViewEvent -> List EventMsg
handleGameView id event = case event of
    GameView.Register req -> [ Register req ]
    GameView.Unregister req -> [ Unregister req ]
    GameView.Send req -> [ Send req ]
    GameView.FetchRuleset set -> [ FetchRuleset set ]

handleGameSelector : GameSelectorEvent -> List EventMsg
handleGameSelector event = case event of
    GameSelector.ChangeCurrent id -> [ SetCurrent id ]

handleEvent : GameLobbyInfo -> List EventMsg -> (GameLobbyInfo, List (Cmd GameLobbyMsg))
handleEvent = changeWithAll2
    (\model event -> case event of
        Register req ->
            let nm = addRegulary model.network req
            in ({model | network = nm }, Cmd.none)
        Unregister req ->
            let nm = removeRegulary model.network req
            in ({ model | network = nm }, Cmd.none)
        Send req ->
            let ncmd = send model.network req
            in (model, Cmd.map MNetwork ncmd)
        FetchRuleset ruleset ->
            let has = hasGameset model.lang (getCurLang model.lang)
                    ruleset
            in if has
                then (model, Cmd.none)
                else (model
                    , fetchModuleLang ruleset
                        (getCurLang model.lang) ModuleLang
                    )
        EnterGroup id ->
            if Dict.member id model.games
            then (model, Cmd.none)
            else
                let (gameView, gcmd, gtasks) =
                        gameViewModule (handleGameView id)
                        (id, case model.ownId of
                            Nothing ->
                                Debug.crash "GameLobby:handleEvent:EnterGroup - require own user id"
                            Just uid -> uid
                        )
                    curGame = Just <| Maybe.withDefault id model.curGame
                    (ng, lcmd, ltasks) = MC.update gameView <|
                        GameView.SetLang model.lang
                    (ns, scmd, stasks) =
                        if curGame /= model.curGame
                        then MC.update model.selector <|
                            GameSelector.SetCurrent curGame
                        else (model.selector, Cmd.none, [])
                    nmodel = { model 
                        | games = Dict.insert id ng model.games
                        , selector = ns
                        , curGame = curGame
                        }
                    (nnmodel, eventCmd) = handleEvent nmodel <| 
                        gtasks ++ ltasks ++ stasks
                in  ( nnmodel
                    , Cmd.batch <|
                        Cmd.map (MGameView id) lcmd ::
                        Cmd.map (MGameView id) gcmd :: 
                        Cmd.map MGameSelector scmd :: 
                        eventCmd
                    )
        SetCurrent id ->
            ( { model | curGame = id }, Cmd.none)
    )

init : (GameLobby, Cmd GameLobbyMsg)
init = 
    let (mgs, cgs, tgs) = gameSelectorModule handleGameSelector
        model = 
            { network = network
            , games = Dict.empty
            , selector = mgs
            , config = empty
            , lang = newGlobal lang_backup
            , curGame = Nothing
            , ownId = Nothing
            , gameNames = Dict.empty
            }
        (tm, tcmd) = handleEvent model tgs
    in  ( GameLobby tm
        , Cmd.batch <|
            [ Cmd.map MNetwork <| send network <| RespMulti <| Multi
                [ RespGet <| GetConfig
                , RespGet <| GetMyGroupUser
                ]
            , fetchUiLang lang_backup MainLang
            , fetchModuleLang "main" lang_backup ModuleLang
            ] ++ tcmd
        )

view : GameLobby -> Html GameLobbyMsg
view (GameLobby model) = div []
    [ stylesheet <| absUrl "ui/css/test-lobby.css"
    , stylesheet "https://fonts.googleapis.com/css?family=Kavivanar&amp;subset=latin-ext"
    , div [ class "w-lobby-selector" ]
        [ div [ class "w-lobby-selector-bar" ]
            [ Html.map MGameSelector <|
                MC.view model.selector
            ]
        ]
    , div [ class "w-lobby-game" ] <| List.singleton <| case Maybe.andThen (flip Dict.get model.games) model.curGame of
        Nothing -> div [ class "w-lobby-nogame" ]
            [ text <| getSingle (createLocal model.lang Nothing)
                [ "lobby", "nogame" ]
            ]
        Just gameView -> div [ class "w-lobby-gameview" ]
            [ Html.map (MGameView (Maybe.withDefault 0 model.curGame)) 
                <| MC.view gameView
            ]

    ]

stylesheet : String -> Html msg
stylesheet url = node "link"
    [ attribute "rel" "stylesheet"
    , attribute "property" "stylesheet"
    , attribute "href" url
    ] []

absUrl : String -> String
absUrl url = uri_host ++ uri_path ++ url

update : GameLobbyMsg -> GameLobby -> (GameLobby, Cmd GameLobbyMsg)
update msg (GameLobby model) = case msg of
    MNetwork wmsg -> case wmsg of
        Received changes ->
            let (nm, ncmd) = Network.update wmsg model.network
                (ng, gcmd, gtasks) = updateAllGames model.games <|
                    Manage changes.changes
                nmodel = { model | network = nm, games = ng }
                (nnmodel, cmd, ctasks) = List.foldr
                    updateConfig (nmodel, [], []) changes.changes
                (tm, tcmd) = handleEvent nnmodel <| gtasks ++ ctasks
            in  ( GameLobby tm
                , Cmd.batch <|
                    [ Cmd.map MNetwork ncmd 
                    , gcmd
                    ] ++ cmd ++ tcmd
                )
        _ ->
            let (nm, cmd) = Network.update wmsg model.network
            in  (GameLobby { model | network = nm }, Cmd.map MNetwork cmd)
    MGameView id wmsg -> case Dict.get id model.games of
        Nothing -> (GameLobby model, Cmd.none)
        Just gameView ->
            let (ng, gcmd, gtasks) = MC.update gameView wmsg
                nmodel = { model | games = Dict.insert id ng model.games }
                (tm, tcmd) = handleEvent nmodel gtasks
            in (GameLobby tm, Cmd.batch <| Cmd.map (MGameView id) gcmd :: tcmd)
    MGameSelector wmsg ->
        let (wm, wcmd, wtasks) = MC.update model.selector wmsg
            nmodel = { model | selector = wm }
            (tm, tcmd) = handleEvent nmodel wtasks
        in  (GameLobby tm, Cmd.batch <| Cmd.map MGameSelector wcmd :: tcmd)
    MainLang lang content ->
        let nm = { model
                | lang = case content of
                    Nothing -> model.lang
                    Just l -> addMainLang model.lang lang l
                }
            (ng, gcmd, gtasks) = updateAllGames model.games <|
                GameView.SetLang nm.lang
            (ns, scmd, stasks) = MC.update model.selector <|
                GameSelector.SetConfig <| LangConfiguration
                model.config <| createLocal model.lang Nothing
            (tm, tcmd) = handleEvent 
                { nm 
                | games = ng 
                , selector = ns
                } 
                <| gtasks ++ stasks
        in  ( GameLobby tm
            , Cmd.batch <| gcmd :: 
                Cmd.map MGameSelector scmd :: tcmd
            )
    ModuleLang mod lang content ->
        let nm = { model
                | lang = case content of
                    Nothing -> model.lang
                    Just l -> addSpecialLang model.lang lang mod l
                }
            (ng, gcmd, gtasks) = updateAllGames model.games <|
                GameView.SetLang nm.lang
            (ns, scmd, stasks) = MC.update model.selector <|
                GameSelector.SetConfig <| LangConfiguration
                model.config <| createLocal model.lang Nothing
            (tm, tcmd) = handleEvent 
                { nm 
                | games = ng 
                , selector = ns
                } 
                <| gtasks ++ stasks
        in  ( GameLobby tm
            , Cmd.batch <| gcmd :: 
                Cmd.map MGameSelector scmd :: tcmd
            )
  
updateConfig : Changes -> (GameLobbyInfo, List (Cmd GameLobbyMsg), List EventMsg) -> (GameLobbyInfo, List (Cmd GameLobbyMsg), List EventMsg)
updateConfig change (m, list, tasks) = case change of
    CConfig str ->
        let config = case Maybe.map decodeConfig str of
                Just conf -> conf
                Nothing -> empty
            (ng, gcmd, gtasks) = updateAllGames m.games 
                <| GameView.SetConfig config
            (ns, scmd, stasks) = MC.update m.selector
                <| GameSelector.SetConfig <|
                LangConfiguration config <|
                createLocal m.lang Nothing
        in  ( { m 
                | config = config
                , games = ng 
                , selector = ns
                }
            , gcmd :: Cmd.map MGameSelector scmd :: list
            , gtasks ++ stasks ++ tasks
            )
    CUser user ->
        if Dict.member user.group m.games
        then (m, list, tasks)
        else
            ( { m | ownId = Just <| Maybe.withDefault user.user m.ownId }
            , list
            , if Dict.member user.group m.games 
                then tasks
                else EnterGroup user.group :: tasks
            )
    CGroup group ->
        let names =  Dict.insert group.id group.name m.gameNames
            (wm, wcmd, wtasks) = MC.update m.selector <|
                GameSelector.SetGames names
        in  ( { m | gameNames = names, selector = wm }
            , Cmd.map MGameSelector wcmd :: list
            , wtasks ++ tasks
            )
    _ -> (m, list, tasks)

updateAllGames : Dict Int (GameViewDef EventMsg) -> GameViewMsg -> (Dict Int (GameViewDef EventMsg), Cmd GameLobbyMsg, List EventMsg)
updateAllGames dict msg =
    let result : List ((Int, GameViewDef EventMsg), (Int, Cmd GameViewMsg), List EventMsg)
        result = List.map
            (\(k,v) ->
                (\ (v1, v2, v3) -> ((k, v1), (k, v2), v3) ) <|
                MC.update v msg
            ) <| Dict.toList dict
        ndict : Dict Int (GameViewDef EventMsg)
        ndict = Dict.fromList <| List.map
            (\(v, _, _) -> v)
            result
        ncmd : Cmd GameLobbyMsg
        ncmd = Cmd.batch <| List.map
            (\(_, (k,v), _) -> Cmd.map (MGameView k) v)
            result
        ntasks : List EventMsg
        ntasks = List.concatMap
            (\(_, _, v) -> v)
            result
    in (ndict, ncmd, ntasks)


subscriptions : GameLobby -> Sub GameLobbyMsg
subscriptions (GameLobby model) = Sub.batch <|
    (Sub.map MNetwork <| Network.subscriptions model.network) ::
    (Sub.map MGameSelector <| MC.subscriptions model.selector) ::
    (List.map 
        (\(k,v) -> 
            Sub.map (MGameView k) <| MC.subscriptions v
        )
        <| Dict.toList model.games
    )