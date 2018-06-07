module Game.Lobby.GameLobby exposing (..)

import ModuleConfig as MC exposing (..)

import Game.UI.GameView as GameView exposing (..)
import Game.Lobby.GameSelector as GameSelector exposing (..)
import Game.Lobby.GameMenu as GameMenu exposing (..)
import Game.Lobby.CreateGroup as CreateGroup exposing (..)
import Game.Lobby.JoinGroup as JoinGroup exposing (..)
import Game.Lobby.Options as Options exposing (..)
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
    , createGroup : CreateGroupDef EventMsg
    , joinGroup : JoinGroupDef EventMsg
    , options : OptionsDef EventMsg
    , config : Configuration
    , lang : LangGlobal
    , curGame : Maybe Int
    , ownId : Maybe Int
    , gameNames : Dict Int String
    , showMenu : Bool
    , menu : GameMenuDef EventMsg
    , modal : ViewModal
    , langs : List LangInfo
    }

type GameLobbyMsg
    = MNetwork NetworkMsg
    | MGameView Int GameViewMsg
    | MCreateGroup CreateGroupMsg
    | MJoinGroup JoinGroupMsg
    | MOptions OptionsMsg
    | MGameSelector GameSelectorMsg
    | MGameMenu GameMenuMsg
    | MainLang String (Maybe String)
    | ModuleLang String String (Maybe String)
    | LangList (List LangInfo)

type EventMsg
    = Register Request
    | Unregister Request
    | Send Request
    | FetchRuleset String
    | EnterGroup Int
    | SetCurrent (Maybe Int)
    | ChangeMenu Bool
    | ChangeModal ViewModal
    | UpdateConfig Configuration

type ViewModal
    = None
    | VMCreateGroup
    | VMJoinGroup
    | VMOptions

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
    GameSelector.OpenMenu -> [ ChangeMenu True ]

handleGameMenu : GameMenuEvent -> List EventMsg
handleGameMenu event = case event of
    GameMenu.CloseMenu -> [ ChangeMenu False ]
    GameMenu.NewGameBox -> [ ChangeMenu False, ChangeModal VMCreateGroup ]
    GameMenu.JoinGameBox -> [ ChangeMenu False, ChangeModal VMJoinGroup ]
    GameMenu.EditGamesBox -> [ ChangeMenu False ]
    GameMenu.LanguageBox -> [ ChangeMenu False ]
    GameMenu.OptionsBox -> [ ChangeMenu False, ChangeModal VMOptions ]

handleCreateGroup : CreateGroupEvent -> List EventMsg
handleCreateGroup event = case event of
    CreateGroup.Close -> [ ChangeModal None ]
    CreateGroup.Create name ->
        [ ChangeModal None
        , Send <| RespControl <| CreateGroup name
        ]

handleJoinGroup : JoinGroupEvent -> List EventMsg
handleJoinGroup event = case event of
    JoinGroup.Close -> [ ChangeModal None ]
    JoinGroup.Join key -> [ Send <| RespControl <| JoinGroup key ]

handleOptions : OptionsEvent -> List EventMsg
handleOptions event = case event of
    Options.Close -> [ ChangeModal None ]
    Options.UpdateConfig conf -> 
        [ UpdateConfig conf
        , Send <| RespControl <| 
            Game.Types.Request.SetConfig <| encodeConfig conf
        ]

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
                    (ng2, lcmd2, ltasks2) = MC.update ng <|
                        GameView.SetConfig model.config
                    (ns, scmd, stasks) =
                        if curGame /= model.curGame
                        then MC.update model.selector <|
                            GameSelector.SetCurrent curGame
                        else (model.selector, Cmd.none, [])
                    nmodel = { model 
                        | games = Dict.insert id ng2 model.games
                        , selector = ns
                        , curGame = curGame
                        }
                    (nnmodel, eventCmd) = handleEvent nmodel <| 
                        gtasks ++ ltasks ++ ltasks2 ++ stasks
                in  ( nnmodel
                    , Cmd.batch <|
                        Cmd.map (MGameView id) lcmd ::
                        Cmd.map (MGameView id) lcmd2 ::
                        Cmd.map (MGameView id) gcmd :: 
                        Cmd.map MGameSelector scmd :: 
                        eventCmd
                    )
        SetCurrent id ->
            ( { model | curGame = id }, Cmd.none)
        ChangeMenu state ->
            ( { model | showMenu = state }, Cmd.none)
        ChangeModal modal ->
            ( { model | modal = modal }, Cmd.none)
        UpdateConfig conf ->
            let lconfig = LangConfiguration conf <| createLocal nm.lang Nothing
                (ng, gcmd, gtasks) = updateAllGames model.games
                    <| GameView.SetConfig conf
                nm = { model | config = conf, games = ng }
                (mpc, cpc, tpc) = pushLangConfig lconfig nm
                (nmodel, eventCmd) = handleEvent mpc <|
                    gtasks ++ tpc
            in  ( nmodel
                , Cmd.batch <| gcmd :: cpc :: eventCmd
                )
    )

init : (GameLobby, Cmd GameLobbyMsg)
init = 
    let (mgs, cgs, tgs) = gameSelectorModule handleGameSelector
        (mgm, cgm, tgm) = gameMenuModule handleGameMenu
        (mcg, ccg, tcg) = createGroupModule handleCreateGroup
        (mjg, cjg, tjg) = joinGroupModule handleJoinGroup
        (mo, co, to) = optionsModule handleOptions
        model = 
            { network = network
            , games = Dict.empty
            , selector = mgs
            , createGroup = mcg
            , joinGroup = mjg
            , options = mo
            , config = empty
            , lang = newGlobal lang_backup
            , curGame = Nothing
            , ownId = Nothing
            , gameNames = Dict.empty
            , showMenu = False
            , menu = mgm
            , modal = None
            , langs = []
            }
        (tm, tcmd) = handleEvent model <| tgs ++ tgm ++ tcg ++ tjg ++ to
    in  ( GameLobby tm
        , Cmd.batch <|
            [ Cmd.map MNetwork <| send network <| RespMulti <| Multi
                [ RespGet <| GetConfig
                , RespGet <| GetMyGroupUser
                ]
            , fetchUiLang lang_backup MainLang
            , fetchModuleLang "main" lang_backup ModuleLang
            , fetchLangList LangList
            , Cmd.map MGameSelector cgs
            , Cmd.map MGameMenu cgm
            , Cmd.map MCreateGroup ccg
            , Cmd.map MJoinGroup cjg
            , Cmd.map MOptions co
            ] ++ tcmd
        )

view : GameLobby -> Html GameLobbyMsg
view (GameLobby model) = div []
    [ stylesheet <| absUrl "ui/css/test-lobby.css"
    , stylesheet "https://fonts.googleapis.com/css?family=Kavivanar&subset=latin-ext"
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
    , if model.showMenu
        then Html.map MGameMenu <| MC.view model.menu
        else div [] []
    , case model.modal of
        None -> div [] []
        VMCreateGroup -> Html.map MCreateGroup <| MC.view model.createGroup
        VMJoinGroup -> Html.map MJoinGroup <| MC.view model.joinGroup
        VMOptions -> Html.map MOptions <| MC.view model.options
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
    MGameMenu wmsg ->
        let (wm, wcmd, wtasks) = MC.update model.menu wmsg
            nmodel = { model | menu = wm }
            (tm, tcmd) = handleEvent nmodel wtasks
        in  (GameLobby tm, Cmd.batch <| Cmd.map MGameMenu wcmd :: tcmd)
    MCreateGroup wmsg ->
        let (wm, wcmd, wtasks) = MC.update model.createGroup wmsg
            nmodel = { model | createGroup = wm }
            (tm, tcmd) = handleEvent nmodel wtasks
        in  (GameLobby tm, Cmd.batch <| Cmd.map MCreateGroup wcmd :: tcmd)
    MJoinGroup wmsg ->
        let (wm, wcmd, wtasks) = MC.update model.joinGroup wmsg
            nmodel = { model | joinGroup = wm }
            (tm, tcmd) = handleEvent nmodel wtasks
        in  (GameLobby tm, Cmd.batch <| Cmd.map MJoinGroup wcmd :: tcmd)
    MOptions wmsg ->
        let (wm, wcmd, wtasks) = MC.update model.options wmsg
            nmodel = { model | options = wm }
            (tm, tcmd) = handleEvent nmodel wtasks
        in  (GameLobby tm, Cmd.batch <| Cmd.map MOptions wcmd :: tcmd)
    MainLang lang content -> updateLang model <|
        case content of
            Nothing -> model.lang
            Just l -> addMainLang model.lang lang l
    ModuleLang mod lang content -> updateLang model <|
        case content of
            Nothing -> model.lang
            Just l -> addSpecialLang model.lang lang mod l
    LangList list ->
        let (mlc, clc, tlc) = MC.update model.language <|
                LanguageChanger.SetLangs list
            (tm, tcmd) = handleEvent { model | language = mlc } tlc
        in  ( GameLobby tm
            , Cmd.batch <| Cmd.map MLanguageChanger clc :: tcmd
            )
        

updateLang : GameLobbyInfo -> LangGlobal -> (GameLobby, Cmd GameLobbyMsg)
updateLang model lang =
    let nm = { model | lang = lang }
        lconfig = LangConfiguration model.config <|
            createLocal lang Nothing
        (ng, gcmd, gtasks) = updateAllGames model.games <|
            GameView.SetLang nm.lang
        (mpc, cpc, tpc) = pushLangConfig lconfig nm
        (tm, tcmd) = handleEvent 
            { mpc
            | games = ng 
            } 
            gtasks
    in  ( GameLobby tm
        , Cmd.batch <| gcmd :: cpc :: tcmd
        )

pushLangConfig : LangConfiguration -> GameLobbyInfo -> (GameLobbyInfo, Cmd GameLobbyMsg, List EventMsg)
pushLangConfig lconfig model =
    let (mgs, cgs, tgs) = MC.update model.selector <|
            GameSelector.SetConfig lconfig
        (mgm, cgm, tgm) = MC.update model.menu <|
            GameMenu.SetConfig lconfig
        (mcg, ccg, tcg) = MC.update model.createGroup <|
            CreateGroup.SetConfig lconfig
        (mjg, cjg, tjg) = MC.update model.joinGroup <|
            JoinGroup.SetConfig lconfig
        (mo, co, to) = MC.update model.options <|
            Options.SetConfig lconfig
    in  ( { model
            | selector = mgs
            , menu = mgm
            , createGroup = mcg
            , joinGroup = mjg
            , options = mo
            }
        , Cmd.batch
            [ Cmd.map MGameSelector cgs
            , Cmd.map MGameMenu cgm
            , Cmd.map MCreateGroup ccg
            , Cmd.map MJoinGroup cjg
            , Cmd.map MOptions co
            ]
        , List.concat
            [ tgs
            , tgm 
            , tcg 
            , tjg
            , to
            ]
        )
  
updateConfig : Changes -> (GameLobbyInfo, List (Cmd GameLobbyMsg), List EventMsg) -> (GameLobbyInfo, List (Cmd GameLobbyMsg), List EventMsg)
updateConfig change (m, list, tasks) = case change of
    CConfig str ->
        ( m
        , list
        , case Maybe.map decodeConfig str of
            Just conf -> UpdateConfig conf :: tasks
            Nothing -> tasks
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
            fetch = if Dict.member group.id m.games
                then []
                else [ EnterGroup group.id, SetCurrent <| Just group.id ]
            closeModal = (m.modal == VMJoinGroup) &&
                ((==) group.enterKey <| JoinGroup.getKey <| MC.getModule m.joinGroup)
            (wm, wcmd, wtasks) = MC.update m.selector <|
                GameSelector.SetGames names
            (mgs, cgs, tgs) = if fetch == []
                then (wm, Cmd.none, [])
                else MC.update wm <| GameSelector.SetCurrent <| Just group.id
        in  ( { m 
                | gameNames = names
                , selector = mgs
                , modal = if closeModal then None else m.modal 
                }
            , Cmd.map MGameSelector wcmd :: 
                Cmd.map MGameSelector cgs :: 
                list
            , fetch ++ wtasks ++ tgs ++ tasks
            )
    CErrInvalidGroupKey ->
        let (mjg, cjg, tjg) = MC.update m.joinGroup <|
                JoinGroup.InvalidKey
        in  ( { m | joinGroup = mjg }
            , Cmd.map MJoinGroup cjg :: list
            , tjg ++ tasks 
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
    (Sub.map MGameMenu <| MC.subscriptions model.menu) ::
    (Sub.map MCreateGroup <| MC.subscriptions model.createGroup) ::
    (Sub.map MJoinGroup <| MC.subscriptions model.joinGroup) ::
    (Sub.map MOptions <| MC.subscriptions model.options) ::
    (List.map 
        (\(k,v) -> 
            Sub.map (MGameView k) <| MC.subscriptions v
        )
        <| Dict.toList model.games
    )