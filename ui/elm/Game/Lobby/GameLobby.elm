module Game.Lobby.GameLobby exposing (..)

import ModuleConfig as MC exposing (..)

import Game.UI.GameView as GameView exposing (..)
import Game.Lobby.GameSelector as GameSelector exposing (..)
import Game.Lobby.GameMenu as GameMenu exposing (..)
import Game.Lobby.CreateGroup as CreateGroup exposing (..)
import Game.Lobby.JoinGroup as JoinGroup exposing (..)
import Game.Lobby.ManageGroups as ManageGroups exposing (..)
import Game.Lobby.LanguageChanger as LanguageChanger exposing (..)
import Game.Lobby.Options as Options exposing (..)
import Game.Lobby.ErrorWindow as ErrorWindow exposing (..)
import Game.Lobby.BanSpecificUser as BanSpecificUser exposing (..)
import Game.Utils.Network as Network exposing (..)
import Game.Types.Request exposing (..)
import Game.Types.Changes exposing (..)
import Game.Types.Types exposing (..)
import Game.Configuration exposing (..)
import Game.Utils.Language exposing (..)
import Game.Utils.LangLoader exposing (..)
import Game.Utils.UserLookup as UserLookup exposing (UserLookup)
import Config exposing (..)

import Html exposing (Html, div, node, program, text)
import Html.Attributes exposing (class, style, attribute)
import Dict exposing (Dict)
import Set exposing (Set)

type GameLobby = GameLobby GameLobbyInfo

type alias GameLobbyInfo =
    { network : Network
    , games : Dict Int (GameViewDef EventMsg)
    , selector : GameSelectorDef EventMsg
    , createGroup : CreateGroupDef EventMsg
    , joinGroup : JoinGroupDef EventMsg
    , manageGroups : ManageGroupsDef EventMsg
    , language : LanguageChangerDef EventMsg
    , options : OptionsDef EventMsg
    , banUser : BanSpecificUserDef EventMsg
    , config : Configuration
    , lang : LangGlobal
    , curGame : Maybe Int
    , ownId : Maybe Int
    , groups : Dict Int Group
    , showMenu : Bool
    , menu : GameMenuDef EventMsg
    , modal : ViewModal
    , langs : List LangInfo
    , error : ErrorWindow
    , users : UserLookup
    }

type GameLobbyMsg
    = MNetwork NetworkMsg
    | MGameView Int GameViewMsg
    | MCreateGroup CreateGroupMsg
    | MJoinGroup JoinGroupMsg
    | MManageGroups ManageGroupsMsg
    | MLanguageChanger LanguageChangerMsg
    | MOptions OptionsMsg
    | MGameSelector GameSelectorMsg
    | MGameMenu GameMenuMsg
    | MBanSpecificUser BanSpecificUserMsg
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
    | ChangeLang String

type ViewModal
    = None
    | VMCreateGroup
    | VMJoinGroup
    | VMManageGroups
    | VMLanguageChanger
    | VMOptions
    | VMBanSpecificUser

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
    GameMenu.EditGamesBox -> [ ChangeMenu False, ChangeModal VMManageGroups ]
    GameMenu.LanguageBox -> [ ChangeMenu False, ChangeModal VMLanguageChanger ]
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

handleBanSpecificUser : BanSpecificUserEvent -> List EventMsg
handleBanSpecificUser event = case event of
    BanSpecificUser.Close -> [ ChangeModal None ]

handleManageGroups : ManageGroupsEvent -> List EventMsg
handleManageGroups event = case event of
    ManageGroups.Close -> [ ChangeModal None ]
    ManageGroups.Focus group ->
        [ ChangeModal None, EnterGroup group ]
    ManageGroups.Leave group ->
        [ Send <| RespControl <| LeaveGroup group]
    ManageGroups.DoBan group user ->
        [ ChangeModal VMBanSpecificUser ]

handleLanguageChanger : LanguageChangerEvent -> List EventMsg
handleLanguageChanger event = case event of
    LanguageChanger.Close -> [ ChangeModal None ]
    LanguageChanger.Change key -> [ ChangeModal None, ChangeLang key ]

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
            ( model
            , Cmd.batch <| List.filterMap
                (\k -> if hasGameset model.lang k ruleset
                    then Nothing
                    else Just <| 
                        fetchModuleLang ruleset k ModuleLang
                )
                <| Set.toList
                <| allLanguages model.lang
            )
        EnterGroup id ->
            if Dict.member id model.games
            then if Just id == model.curGame 
                then (model, Cmd.none)
                else
                    let 
                        (ns, scmd, stasks) = MC.update model.selector <|
                                GameSelector.SetCurrent <| Just id
                        (nmodel, eventCmd) = handleEvent
                            { model
                            | curGame = Just id
                            , selector = ns
                            }
                            stasks
                    in  ( nmodel
                        , Cmd.batch <|
                            Cmd.map MGameSelector scmd ::
                            eventCmd
                        )
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
            let (ng, gcmd, gtasks) = updateAllGames model.games
                    <| GameView.SetConfig conf
                nm = { model | config = conf, games = ng }
                lconfig = LangConfiguration conf <| createLocal nm.lang Nothing
                (mpc, cpc, tpc) = pushLangConfig lconfig nm
                (nmodel, eventCmd) = handleEvent mpc <|
                    gtasks ++ tpc
            in  ( nmodel
                , Cmd.batch <| gcmd :: cpc :: eventCmd
                )
        ChangeLang key ->
            if getCurLang model.lang == key
            then ( model, Cmd.none )
            else 
                let conf1 = model.config
                    conf2 = { conf1 | language = key }
                    lang = updateCurrentLang model.lang key
                    (GameLobby m, cmd) = updateLang
                        { model | config = conf2 }
                        lang
                    (mgm, cgm, tgm) = MC.update m.menu <|
                        GameMenu.SetLang key
                    requests = if hasLanguage lang key
                        then []
                        else (::) (fetchUiLang key MainLang)
                            <| List.map (\m -> fetchModuleLang m key ModuleLang)
                            <| Set.toList
                            <| allGamesets lang
                    (nmodel, eventCmd) = handleEvent
                        { m | menu = mgm } <|
                        tgm ++
                        [ UpdateConfig conf2
                        , Send <| RespControl <| 
                            Game.Types.Request.SetConfig <| encodeConfig conf2
                        ]
                in  ( nmodel
                    , Cmd.batch <| cmd :: 
                        Cmd.map MGameMenu cgm :: 
                        eventCmd ++ 
                        requests
                    )

    )

init : (GameLobby, Cmd GameLobbyMsg)
init = 
    let (mgs, cgs, tgs) = gameSelectorModule handleGameSelector
        (mgm, cgm, tgm) = gameMenuModule handleGameMenu
        (mcg, ccg, tcg) = createGroupModule handleCreateGroup
        (mjg, cjg, tjg) = joinGroupModule handleJoinGroup
        (mmg, cmg, tmg) = manageGroupsModule handleManageGroups
        (mlc, clc, tlc) = languageChangerModule handleLanguageChanger
        (mo, co, to) = optionsModule handleOptions
        (mbs, cbs, tbs) = banSpecificUserModule handleBanSpecificUser
        model = 
            { network = network
            , games = Dict.empty
            , selector = mgs
            , createGroup = mcg
            , joinGroup = mjg
            , manageGroups = mmg
            , language = mlc
            , options = mo
            , banUser = mbs
            , config = empty
            , lang = newGlobal lang_backup
            , curGame = Nothing
            , ownId = Nothing
            , groups = Dict.empty
            , showMenu = False
            , menu = mgm
            , modal = None
            , langs = []
            , error = NoError
            , users = UserLookup.empty
            }
        (tm, tcmd) = handleEvent model <| tgs ++ tgm ++ tcg ++ tjg ++ tmg ++ tlc ++ to ++ tbs
    in  ( GameLobby tm
        , Cmd.batch <|
            [ Cmd.map MNetwork <| send network <| RespMulti <| Multi
                [ RespGet <| GetConfig
                , RespGet <| GetOwnUserStat
                , RespGet <| GetMyGroupUser
                ]
            , fetchUiLang lang_backup MainLang
            -- , fetchModuleLang "main" lang_backup ModuleLang
            , fetchLangList LangList
            , Cmd.map MGameSelector cgs
            , Cmd.map MGameMenu cgm
            , Cmd.map MCreateGroup ccg
            , Cmd.map MJoinGroup cjg
            , Cmd.map MManageGroups cmg
            , Cmd.map MLanguageChanger clc
            , Cmd.map MOptions co
            , Cmd.map MBanSpecificUser cbs
            ] ++ tcmd
        )

view : GameLobby -> Html GameLobbyMsg
view (GameLobby model) = div [] <| viewStyles 
    [ div [ class "w-lobby-selector" ]
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
    , if model.error /= NoError 
        then viewError (createLocal model.lang Nothing) model.error
        else case model.modal of
            None -> div [] []
            VMCreateGroup -> Html.map MCreateGroup <| MC.view model.createGroup
            VMJoinGroup -> Html.map MJoinGroup <| MC.view model.joinGroup
            VMManageGroups -> Html.map MManageGroups <| MC.view model.manageGroups
            VMOptions -> Html.map MOptions <| MC.view model.options
            VMLanguageChanger -> Html.map MLanguageChanger <| MC.view model.language
            VMBanSpecificUser -> Html.map MBanSpecificUser <| MC.view model.banUser
    , stylesheet <| uri_host ++ uri_path ++ "ui/css/themes/" ++ model.config.theme ++ ".css"
    ]

viewStyles : List (Html msg) -> List (Html msg)
viewStyles content =
    if run_build
    then content
    else 
        [ stylesheet <| absUrl "ui/css/test-lobby.css"
        , stylesheet "https://fonts.googleapis.com/css?family=Kavivanar&subset=latin-ext"
        ] ++ content

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
                users = UserLookup.putChanges changes.changes model.users
                (mmg, cmg, tmg) = MC.update model.manageGroups <|
                    ManageGroups.SetUsers users
                nmodel = { model 
                    | network = nm
                    , games = ng 
                    , users = users
                    , manageGroups = mmg
                    }
                (nnmodel, cmd, ctasks) = List.foldr
                    updateConfig (nmodel, [], []) changes.changes
                (tm, tcmd) = handleEvent nnmodel <| gtasks ++ tmg ++ ctasks
            in  ( GameLobby tm
                , Cmd.batch <|
                    [ Cmd.map MNetwork ncmd 
                    , Cmd.map MManageGroups cmg
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
    MBanSpecificUser wmsg ->
        let (wm, wcmd, wtasks) = MC.update model.banUser wmsg
            nmodel = { model | banUser = wm }
            (tm, tcmd) = handleEvent nmodel wtasks
        in  (GameLobby tm, Cmd.batch <| Cmd.map MBanSpecificUser wcmd :: tcmd)
    MManageGroups wmsg ->
        let (wm, wcmd, wtasks) = MC.update model.manageGroups wmsg
            nmodel = { model | manageGroups = wm }
            (tm, tcmd) = handleEvent nmodel wtasks
        in  (GameLobby tm, Cmd.batch <| Cmd.map MManageGroups wcmd :: tcmd)
    MLanguageChanger wmsg ->
        let (wm, wcmd, wtasks) = MC.update model.language wmsg
            nmodel = { model | language = wm }
            (tm, tcmd) = handleEvent nmodel wtasks
        in  (GameLobby tm, Cmd.batch <| Cmd.map MLanguageChanger wcmd :: tcmd)
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
        (mmg, cmg, tmg) = MC.update model.manageGroups <|
            ManageGroups.SetConfig lconfig
        (mlc, clc, tlc) = MC.update model.language <|
            LanguageChanger.SetConfig lconfig
        (mo, co, to) = MC.update model.options <|
            Options.SetConfig lconfig
        (mbs, cbs, tbs) = MC.update model.banUser <|
            BanSpecificUser.SetConfig lconfig
    in  ( { model
            | selector = mgs
            , menu = mgm
            , createGroup = mcg
            , joinGroup = mjg
            , manageGroups = mmg
            , language = mlc
            , options = mo
            , banUser = mbs
            }
        , Cmd.batch
            [ Cmd.map MGameSelector cgs
            , Cmd.map MGameMenu cgm
            , Cmd.map MCreateGroup ccg
            , Cmd.map MJoinGroup cjg
            , Cmd.map MManageGroups cmg
            , Cmd.map MLanguageChanger clc
            , Cmd.map MOptions co
            , Cmd.map MBanSpecificUser cbs
            ]
        , List.concat
            [ tgs
            , tgm 
            , tcg 
            , tjg
            , tmg
            , tlc
            , to
            , tbs
            ]
        )

updateConfig : Changes -> (GameLobbyInfo, List (Cmd GameLobbyMsg), List EventMsg) -> (GameLobbyInfo, List (Cmd GameLobbyMsg), List EventMsg)
updateConfig change (m, list, tasks) = case change of
    CConfig str ->
        ( m
        , list
        , case Maybe.map decodeConfig str of
            Just conf -> UpdateConfig conf ::
                ChangeLang conf.language ::
                tasks
            Nothing -> tasks
        )
    COwnId id ->
        pushOwnId
        { m | ownId = Just <| Maybe.withDefault id m.ownId }
        list
        tasks
    CUser user ->
        if Dict.member user.group m.games
        then (m, list, tasks)
        else pushOwnId
            { m | ownId = Just <| Maybe.withDefault user.user m.ownId }
            list
            <| if Dict.member user.group m.games 
                then tasks
                else EnterGroup user.group :: tasks
    CGroup group ->
        let groups : Dict Int Group
            groups =  Dict.insert group.id group m.groups
            fetch = if Dict.member group.id m.games
                then []
                else [ EnterGroup group.id, SetCurrent <| Just group.id ]
            closeModal = (m.modal == VMJoinGroup) &&
                ((==) group.enterKey <| JoinGroup.getKey <| MC.getModule m.joinGroup)
            (wm, wcmd, wtasks) = MC.update m.selector <|
                GameSelector.SetGames <| Dict.map (\_ -> .name) groups
            (mgs, cgs, tgs) = if fetch == []
                then (wm, Cmd.none, [])
                else MC.update wm <| GameSelector.SetCurrent <| Just group.id
            (mmg, cmg, tmg) = MC.update m.manageGroups <|
                ManageGroups.SetGroups groups
        in  ( { m 
                | groups = groups
                , selector = mgs
                , manageGroups = mmg
                , modal = if closeModal then None else m.modal 
                }
            , Cmd.map MGameSelector wcmd :: 
                Cmd.map MGameSelector cgs :: 
                Cmd.map MManageGroups cmg ::
                list
            , fetch ++ wtasks ++ tgs ++ tmg ++ tasks
            )
    CErrInvalidGroupKey ->
        let (mjg, cjg, tjg) = MC.update m.joinGroup <|
                JoinGroup.InvalidKey
        in  ( { m | joinGroup = mjg }
            , Cmd.map MJoinGroup cjg :: list
            , tjg ++ tasks 
            )
    CErrJoinBannedFromGroup ->
        let (mjg, cjg, tjg) = MC.update m.joinGroup <|
                JoinGroup.UserBanned
        in  ( { m | joinGroup = mjg }
            , Cmd.map MJoinGroup cjg :: list
            , tjg ++ tasks
            )
    CAccountInvalid ->
        ( { m | error = AccountError }, list, tasks)
    CNetworkError ->
        ( { m | error = NetworkError }, list, tasks)
    CMaintenance ->
        ( { m | error = Maintenance }, list, tasks)
    CGroupLeaved id ->
        let game = Dict.get id m.games
            tgv = case game of
                Just g -> (\(m,c,t)->t) <| MC.update g GameView.Disposing
                Nothing -> []
            groups = Dict.remove id m.groups
            games = Dict.remove id m.games
            curGame = if Just id == m.curGame
                then List.head <| Dict.keys groups
                else m.curGame
            (mgs, cgs, tgs) = MC.update m.selector <|
                GameSelector.SetGames <| Dict.map (\_ -> .name) groups
            (mgs2, cgs2, tgs2) = MC.update mgs <|
                GameSelector.SetCurrent curGame
            (mmg, cmg, tmg) = MC.update m.manageGroups <|
                ManageGroups.SetGroups groups
            mm = { m 
                | groups = groups
                , games = games
                , curGame = curGame
                , selector = mgs2
                , manageGroups = mmg
                }
        in  ( mm
            , Cmd.map MGameSelector cgs ::
                Cmd.map MGameSelector cgs2 ::
                Cmd.map MManageGroups cmg ::
                list
            , tgv ++ tgs ++ tgs2 ++ tmg ++ tasks
            )
    _ -> (m, list, tasks)

pushOwnId : GameLobbyInfo -> List (Cmd GameLobbyMsg) -> List EventMsg -> (GameLobbyInfo, List (Cmd GameLobbyMsg), List EventMsg)
pushOwnId m list tasks = 
    let (mmg, cmg, tmg) = case m.ownId of
            Just id -> MC.update m.manageGroups <|
                ManageGroups.SetOwnId id
            Nothing -> (m.manageGroups, Cmd.none, [])
    in  ( { m | manageGroups = mmg }
        , Cmd.map MManageGroups cmg :: list
        , tmg ++ tasks
        )

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
subscriptions (GameLobby model) = if model.error /= NoError then Sub.none else Sub.batch <|
    (Sub.map MNetwork <| Network.subscriptions model.network) ::
    (Sub.map MGameSelector <| MC.subscriptions model.selector) ::
    (Sub.map MGameMenu <| MC.subscriptions model.menu) ::
    (Sub.map MCreateGroup <| MC.subscriptions model.createGroup) ::
    (Sub.map MJoinGroup <| MC.subscriptions model.joinGroup) ::
    (Sub.map MManageGroups <| MC.subscriptions model.manageGroups) ::
    (Sub.map MLanguageChanger <| MC.subscriptions model.language) ::
    (Sub.map MOptions <| MC.subscriptions model.options) ::
    (Sub.map MBanSpecificUser <| MC.subscriptions model.banUser) ::
    (List.map 
        (\(k,v) -> 
            Sub.map (MGameView k) <| MC.subscriptions v
        )
        <| Dict.toList model.games
    )