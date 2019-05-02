module Game.Lobby.GameLobby exposing (..)

import Game.UI.GameView as GameView exposing (..)
import Game.UI.Tutorial as Tutorial exposing (..)
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
import Game.Types.Request as Request exposing (..)
import Game.Types.Changes exposing (..)
import Game.Types.Types as Types exposing (..)
import Game.Configuration exposing (..)
import Game.Utils.Language exposing (..)
import Game.Utils.LangLoader exposing (..)
import Game.Utils.UserLookup as UserLookup exposing (UserLookup)
import Config exposing (..)

import Game.Data as Data exposing (..)
import DataDiff.Path as Diff exposing (DetectorPath, Path (..))
import DataDiff.Ex exposing (SingleActionEx (..), ModActionEx (..))
import UnionDict exposing (UnionDict, SafeDict)

import Html exposing (Html, div, node, text)
import Html.Attributes exposing (class, style, attribute)
import Dict exposing (Dict)
import Set exposing (Set)
import Maybe.Extra as MaybeEx

-- elm/Browser
import Browser 

type GameLobby = GameLobby GameLobbyInfo

type alias GameLobbyInfo =
    { games : SafeDict Int GroupId GameView
    , selector : GameSelector
    , createGroup : CreateGroup
    , joinGroup : JoinGroup
    , manageGroups : ManageGroups
    , banUser : BanSpecificUser
    , curGame : Maybe GroupId
    , showMenu : Bool
    , modal : ViewModal
    , tutorial : Tutorial
    }

type GameLobbyMsg
    = MGameView GroupId GameViewMsg
    | MCreateGroup CreateGroupMsg
    | MJoinGroup JoinGroupMsg
    | MManageGroups ManageGroupsMsg
    | MLanguageChanger LanguageChangerMsg
    | MOptions OptionsMsg
    | MGameSelector GameSelectorMsg
    | MGameMenu GameMenuMsg
    | MBanSpecificUser BanSpecificUserMsg
    | MTutorial TutorialMsg
    | ReceiveMainLang String (Maybe String)
    | ReceiveModuleLang String String (Maybe String)
    | ReceiveLangList (List LangInfo)
    | RefreshLangList
    | PrepareBan GroupId UserId
    | ChangeLang String
    | SetCurrentGroup GroupId
    | SetModal ViewModal
    | SetGameMenuVisible Bool
    | RemoveGroup GroupId
    | FetchLangset String
    | SubmitFetchLangset String String
    | CallEvent (List GameLobbyEvent)
    | AddGroup GroupId
    | CallRemoveGroup GroupId

type GameLobbyEvent 
    = Register Request
    | Unregister Request
    | Send Request
    | CallMsg GameLobbyMsg
    | ReqData (Data -> GameLobbyMsg)
    | ModData (Data -> Data)

type ViewModal
    = None
    | VMCreateGroup
    | VMJoinGroup
    | VMManageGroups
    | VMLanguageChanger
    | VMOptions
    | VMBanSpecificUser
    | VMTutorial

detector : GameLobby -> DetectorPath Data GameLobbyMsg
detector (GameLobby model)= Diff.batch
    [ Diff.mapMsg MJoinGroup 
        <| JoinGroup.detector model.joinGroup
    , Diff.mapMsg MOptions Options.detector
    , Diff.batch
        <| List.map 
            (\(id, game) -> GameView.detector game
                |> Diff.mapMsg (MGameView id)
            )
        <| UnionDict.toList
        <| UnionDict.unsafen GroupId Types.groupId model.games
    , detectorInternal <| GameLobby model
    ]

detectorInternal : GameLobby -> DetectorPath Data GameLobbyMsg
detectorInternal (GameLobby model) = Data.pathGameData
    <| Diff.batch
    [ Diff.mapData .fetchGroups
        <| Diff.list (\_ _ -> PathInt)
            [ AddedEx <| \_ id -> CallEvent
                [ Send <| ReqGet <| GetGroup id
                ]
            ]
        <| Diff.noOp
    , pathGroupData 
        [ AddedEx <| \_ group -> AddGroup group.group.id
        , RemovedEx <| \_ group -> CallRemoveGroup group.group.id
        ] 
        <| Diff.noOp
    ]

mapGameViewEvent : GroupId -> GameViewEvent -> GameLobbyEvent
mapGameViewEvent id event = case event of 
    GameView.Register req -> Register req
    GameView.Unregister req -> Unregister req 
    GameView.Send req -> Send req
    GameView.FetchRoleset roleset -> ReqData <| \data ->
        if Dict.get roleset data.game.rolesets /= Nothing
        then CallEvent []
        else CallEvent [ Send <| ReqInfo <| Rolesets roleset ]
    GameView.FetchLangset lang -> CallMsg <| FetchLangset lang 
    GameView.CallMsg msg -> CallMsg <| MGameView id msg
    GameView.ReqData req -> ReqData <| MGameView id << req
    GameView.IsDisposed -> CallMsg <| RemoveGroup id
    GameView.ModData mod -> ModData mod
    GameView.RefreshLangList -> CallMsg RefreshLangList

mapBanSpecificUserEvent : BanSpecificUserEvent -> GameLobbyEvent 
mapBanSpecificUserEvent event = case event of 
    BanSpecificUser.Close -> CallMsg <| SetModal None
    BanSpecificUser.Create req -> Send req 
    BanSpecificUser.ReqData req -> ReqData <| MBanSpecificUser << req

mapCreateGroupEvent : CreateGroupEvent -> GameLobbyEvent 
mapCreateGroupEvent event = case event of 
    CreateGroup.Close -> CallMsg <| SetModal None
    CreateGroup.Create name -> Send <| ReqControl <| CreateGroup name

mapGameMenuEvent : GameMenuEvent -> GameLobbyEvent 
mapGameMenuEvent event = case event of 
    GameMenu.CloseMenu -> CallMsg <| SetGameMenuVisible False
    GameMenu.NewGameBox -> CallMsg <| SetModal VMCreateGroup
    GameMenu.JoinGameBox -> CallMsg <| SetModal VMJoinGroup
    GameMenu.EditGamesBox -> CallMsg <| SetModal VMManageGroups
    GameMenu.LanguageBox -> CallMsg <| SetModal VMLanguageChanger
    GameMenu.OptionsBox -> CallMsg <| SetModal VMOptions
    GameMenu.TutorialBox -> CallMsg <| SetModal VMTutorial

mapGameSelectorEvent : GameSelectorEvent -> GameLobbyEvent
mapGameSelectorEvent event = case event of 
    GameSelector.ChangeCurrent id -> CallMsg <| SetCurrentGroup id 
    GameSelector.OpenMenu -> CallMsg <| SetGameMenuVisible True

mapJoinGroupEvent : JoinGroupEvent -> GameLobbyEvent
mapJoinGroupEvent event = case event of 
    JoinGroup.Close -> CallMsg <| SetModal None 
    JoinGroup.Join key -> Send <| ReqControl <| Request.JoinGroup key

mapLanguageChangerEvent : LanguageChangerEvent -> GameLobbyEvent
mapLanguageChangerEvent event = case event of 
    LanguageChanger.Close -> CallMsg <| SetModal None 
    LanguageChanger.Change lang -> CallMsg <| ChangeLang lang 

mapManageGroupsEvent : ManageGroupsEvent -> GameLobbyEvent
mapManageGroupsEvent event = case event of 
    ManageGroups.Close -> CallMsg <| SetModal None 
    ManageGroups.Focus id -> CallMsg <| SetCurrentGroup id 
    ManageGroups.Leave id -> Send <| ReqControl <| LeaveGroup id
    ManageGroups.DoBan group user -> CallMsg <| PrepareBan group user 
    ManageGroups.FetchBans group -> CallMsg <| CallEvent
        [ ModData <| \data ->
            { data 
            | game = data.game |> \game ->
                { game
                | bans = game.bans
                    |> List.filter ((/=) group << .group)
                }
            }
        , Send <| ReqGet <| GetBansFromGroup group
        ]
    ManageGroups.Unban group user -> Send <| ReqControl <| RevokeBan user group

mapOptionsEvent : OptionsEvent -> GameLobbyEvent
mapOptionsEvent event = case event of 
    Options.Close -> CallMsg <| SetModal None 
    Options.ModData mod -> ModData mod 
    Options.SaveConfig conf -> Send 
        <| ReqControl <| SetConfig <| encodeConfig conf


init : (GameLobby, Cmd GameLobbyMsg, List GameLobbyEvent)
init = 
    let (mt, ct) = Tutorial.init
        model = 
            { games = UnionDict.include Dict.empty
            , selector = GameSelector.init
            , createGroup = CreateGroup.init
            , joinGroup = JoinGroup.init
            , manageGroups = ManageGroups.init
            , banUser = BanSpecificUser.init (UserId 0) (GroupId 0)
            , curGame = Nothing
            , showMenu = False
            , modal = None
            , tutorial = mt
            }
    in  ( GameLobby model
        , Cmd.batch <|
            [ fetchUiLang lang_backup ReceiveMainLang
            -- , fetchModuleLang "main" lang_backup ModuleLang
            , fetchLangList ReceiveLangList
            , Cmd.map MTutorial ct
            ]
        ,   [ Send <| ReqMulti <| Multi
                [ ReqGet <| GetConfig 
                , ReqGet <| GetOwnUserStat
                , ReqGet <| GetMyGroupUser
                ]
            ]
        )

view : Data -> GameLobby -> Html GameLobbyMsg
view data (GameLobby model) = div [] <| viewStyles 
    [ div [ class "w-lobby-selector" ]
        [ div [ class "w-lobby-selector-bar" ]
            [ Html.map MGameSelector
                <| GameSelector.view data model.selector
            ]
        ]
    , div [ class "w-lobby-game" ] 
        <| List.singleton 
        <|  let curGame : Maybe GameView
                curGame = model.curGame
                    |> Maybe.andThen 
                        (\k -> model.games
                            |> UnionDict.unsafen GroupId Types.groupId
                            |> UnionDict.get k
                        )
            in case Maybe.map2 Tuple.pair model.curGame curGame of
                Nothing -> div [ class "w-lobby-nogame" ]
                    [ Html.map MTutorial 
                        <| Tutorial.viewEmbed 
                            data.lang.default
                            model.tutorial
                    --[ text <| getSingle (createLocal model.lang Nothing)
                    --    [ "lobby", "nogame" ]
                    ]
                Just (id, gameView) -> div 
                    [ class "w-lobby-gameview" ]
                    [ Html.map (MGameView id) 
                        <| GameView.view data 
                            (data.lang.locals 
                                |> UnionDict.unsafen GroupId Types.groupId
                                |> UnionDict.get id
                                |> Maybe.withDefault data.lang.default
                            )
                        <| gameView
                    ]
    , if model.showMenu
        then Html.map MGameMenu <| GameMenu.view data.lang.default
        else div [] []
    , if data.error /= NoError 
        then viewError data.lang.default data.error
        else case model.modal of
            None -> div [] []
            VMCreateGroup -> Html.map MCreateGroup 
                <| CreateGroup.view data.lang.default model.createGroup
            VMJoinGroup -> Html.map MJoinGroup 
                <| JoinGroup.view data data.lang.default model.joinGroup
            VMManageGroups -> Html.map MManageGroups 
                <| ManageGroups.view data data.lang.default model.manageGroups
            VMOptions -> Html.map MOptions 
                <| Options.view data data.lang.default
            VMLanguageChanger -> Html.map MLanguageChanger 
                <| LanguageChanger.view data data.lang.default
            VMBanSpecificUser -> Html.map MBanSpecificUser 
                <| BanSpecificUser.view data data.lang.default model.banUser
            VMTutorial -> Tutorial.viewModal 
                MTutorial 
                (SetModal None)
                data.lang.default
                model.tutorial
    , stylesheet 
        <| uri_host 
        ++ uri_path 
        ++ "ui/css/themes/" 
        ++ data.config.theme 
        ++ ".less"
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

update : GameLobbyMsg -> GameLobby -> (GameLobby, Cmd GameLobbyMsg, List GameLobbyEvent)
update msg (GameLobby model) = case msg of
    MGameView id wmsg -> 
        case UnionDict.unsafen GroupId Types.groupId model.games 
            |> UnionDict.get id
        of
            Nothing -> (GameLobby model, Cmd.none, [])
            Just gameView ->
                let (ng, gcmd, gevents) = GameView.update wmsg gameView
                in  ( GameLobby
                        { model
                        | games = model.games
                            |> UnionDict.unsafen GroupId Types.groupId
                            |> UnionDict.insert id ng 
                            |> UnionDict.safen
                        }
                    , Cmd.map (MGameView id) gcmd
                    , List.map (mapGameViewEvent id) gevents
                    )
    MGameSelector wmsg ->
        let (wm, wcmd, wtasks) = GameSelector.update wmsg model.selector
        in  ( GameLobby { model | selector = wm }
            , Cmd.map MGameSelector wcmd
            , List.map mapGameSelectorEvent wtasks
            )
    MGameMenu wmsg ->
        let wtasks = GameMenu.update wmsg
        in  (GameLobby model, Cmd.none, List.map mapGameMenuEvent wtasks)
    MCreateGroup wmsg ->
        let (wm, wcmd, wtasks) = CreateGroup.update wmsg model.createGroup
        in  ( GameLobby { model | createGroup = wm }
            , Cmd.map MCreateGroup wcmd
            , List.map mapCreateGroupEvent wtasks
            )
    MJoinGroup wmsg ->
        let (wm, wcmd, wtasks) = JoinGroup.update wmsg model.joinGroup
        in  ( GameLobby { model | joinGroup = wm }
            ,Cmd.map MJoinGroup wcmd
            , List.map mapJoinGroupEvent wtasks
            )
    MBanSpecificUser wmsg ->
        let (wm, wcmd, wtasks) = BanSpecificUser.update wmsg model.banUser
        in  ( GameLobby { model | banUser = wm }
            , Cmd.map MBanSpecificUser wcmd
            , List.map mapBanSpecificUserEvent wtasks
            )
    MManageGroups wmsg ->
        let (wm, wcmd, wtasks) = ManageGroups.update wmsg model.manageGroups
        in  ( GameLobby { model | manageGroups = wm }
            , Cmd.map MManageGroups wcmd
            , List.map mapManageGroupsEvent wtasks
            )
    MLanguageChanger wmsg ->
        let wtasks = LanguageChanger.update wmsg
        in  (GameLobby model, Cmd.none, List.map mapLanguageChangerEvent wtasks)
    MOptions wmsg ->
        let wtasks = Options.update wmsg
        in  (GameLobby model, Cmd.none, List.map mapOptionsEvent wtasks)
    MTutorial wmsg ->
        let (wm, wcmd) = Tutorial.update wmsg model.tutorial
        in (GameLobby { model | tutorial = wm }, Cmd.map MTutorial wcmd, [])
    ReceiveMainLang lang content -> case content of 
        Just cont -> updateLang (GameLobby model) 
            <| \glob -> addMainLang glob lang cont
        Nothing -> (GameLobby model, Cmd.none, [])
    ReceiveModuleLang mod lang content -> case content of 
        Just cont -> updateLang (GameLobby model) 
            <| \glob -> addSpecialLang glob lang mod cont
        Nothing -> (GameLobby model, Cmd.none, [])
    RefreshLangList -> updateLang (GameLobby model) identity
    ReceiveLangList list ->
        ( GameLobby model 
        , Cmd.none 
        , List.singleton <| ModData <| \data ->
            { data 
            | lang = data.lang |> \lang ->
                { lang | info = list }
            }
        )
    PrepareBan group user ->
        ( GameLobby 
            { model 
            | banUser = BanSpecificUser.init user group
            , modal = VMBanSpecificUser
            , showMenu = False
            }
        , Cmd.none 
        , []
        )
    ChangeLang lang -> 
        updateLang (GameLobby model) 
            <| \glob -> updateCurrentLang glob lang
    SetCurrentGroup group ->    
        ( GameLobby { model | curGame = Just group }, Cmd.none, [])
    SetModal modal ->
        ( GameLobby { model | modal = modal, showMenu = False }, Cmd.none, [])
    SetGameMenuVisible menu ->
        ( GameLobby { model | showMenu = menu }, Cmd.none, [])
    RemoveGroup group ->
        ( GameLobby 
            { model 
            | games = model.games
                |> UnionDict.unsafen GroupId Types.groupId
                |> UnionDict.remove group 
                |> UnionDict.safen
            }
        , Cmd.none
        , []
        )
    FetchLangset mod ->
        ( GameLobby model 
        , Cmd.none 
        , List.singleton <| ReqData
            (\data ->
                if hasGameset data.lang.global
                    (getCurLang data.lang.global)
                    mod
                then CallEvent []
                else SubmitFetchLangset mod
                    <| getCurLang data.lang.global
            )
        )
    SubmitFetchLangset mod lang ->
        ( GameLobby model
        , fetchModuleLang mod lang ReceiveModuleLang
        , []
        )
    CallEvent event ->
        ( GameLobby model 
        , Cmd.none 
        , event 
        )
    AddGroup id ->
        let (ng, nc, ne) = GameView.init id
        in  ( GameLobby
                { model
                | games = model.games
                    |> UnionDict.unsafen GroupId Types.groupId
                    |> UnionDict.insert id ng
                    |> UnionDict.safen
                , curGame = model.curGame
                    |> Maybe.withDefault id 
                    |> Just
                }
            , Cmd.map (MGameView id) nc
            , List.map (mapGameViewEvent id) ne 
                ++  ( if model.curGame == Nothing
                        then List.singleton
                            <| CallMsg 
                            <| MGameSelector
                            <| GameSelector.msgSetCurrent 
                            <| Just id
                        else []
                    )
            )
    CallRemoveGroup id ->
        ( GameLobby model 
        , Cmd.none 
        ,   [ ModData <| \data ->
                { data
                | game = data.game |> \game ->
                    { game 
                    | bans = game.bans 
                        |> List.filter
                            ((/=) id << .group)
                    }
                }
            ]
        )
        
updateLang : GameLobby -> (LangGlobal -> LangGlobal) -> (GameLobby, Cmd GameLobbyMsg, List GameLobbyEvent)
updateLang model func = 
    ( model 
    , Cmd.none 
    , List.singleton <| ModData <| \data ->
        { data 
        | lang = data.lang |> \lang ->
            let global : LangGlobal
                global = func lang.global
            in  { lang 
                | global = global
                , locals = data.game.groups
                    |> UnionDict.unsafen GroupId Types.groupId
                    |> UnionDict.map
                        (\_ g -> 
                            let ruleset : Maybe String 
                                ruleset = g.group.currentGame 
                                    |> Maybe.map .ruleset
                                finished : Bool 
                                finished = g.group.currentGame 
                                    |> Maybe.map (.finished >> MaybeEx.isJust)
                                    |> Maybe.withDefault True
                                newGame : Maybe String
                                newGame = g.newGameLang
                                target : Maybe String
                                target = 
                                    if finished
                                    then MaybeEx.or newGame ruleset
                                    else ruleset
                            in createLocal global target
                        )
                    |> UnionDict.safen 
                , default = createLocal global Nothing
                }
        }
    )


-- updateConfig : Changes 
--     -> (GameLobbyInfo, List (Cmd GameLobbyMsg), List EventMsg) 
--     -> (GameLobbyInfo, List (Cmd GameLobbyMsg), List EventMsg)
-- updateConfig change (m, list, tasks) = case change of
--     CUser user ->
--         if Dict.member user.group m.games
--         then (m, list, tasks)
--         else pushOwnId
--             { m | ownId = Just <| Maybe.withDefault user.user m.ownId }
--             list
--             <| if Dict.member user.group m.games 
--                 then tasks
--                 else EnterGroup user.group :: tasks
--     CGroup group ->
--         let groups : Dict Int Group
--             groups =  Dict.insert group.id group m.groups
--             fetch = if Dict.member group.id m.games
--                 then []
--                 else [ EnterGroup group.id, SetCurrent <| Just group.id ]
--             closeModal = (m.modal == VMJoinGroup) &&
--                 ((==) group.enterKey <| JoinGroup.getKey <| MC.getModule m.joinGroup)
--             (wm, wcmd, wtasks) = MC.update m.selector <|
--                 GameSelector.msgSetGames <| Dict.map (\_ -> .name) groups
--             (mgs, cgs, tgs) = if fetch == []
--                 then (wm, Cmd.none, [])
--                 else MC.update wm <| GameSelector.msgSetCurrent <| Just group.id
--             (mmg, cmg, tmg) = MC.update m.manageGroups <|
--                 ManageGroups.msgSetGroups groups
--         in  ( { m 
--                 | groups = groups
--                 , selector = mgs
--                 , manageGroups = mmg
--                 , modal = if closeModal then None else m.modal 
--                 }
--             , Cmd.map MGameSelector wcmd :: 
--                 Cmd.map MGameSelector cgs :: 
--                 Cmd.map MManageGroups cmg ::
--                 list
--             , fetch ++ wtasks ++ tgs ++ tmg ++ tasks
--             )
--     CGroupLeaved id ->
--         let game = Dict.get id m.games
--             tgv = case game of
--                 Just g -> (\(_, _, t) -> t) 
--                     <| MC.update g GameView.msgDisposing
--                 Nothing -> []
--             groups = Dict.remove id m.groups
--             games = Dict.remove id m.games
--             curGame = if Just id == m.curGame
--                 then List.head <| Dict.keys groups
--                 else m.curGame
--             (mgs, cgs, tgs) = MC.update m.selector <|
--                 GameSelector.msgSetGames <| Dict.map (\_ -> .name) groups
--             (mgs2, cgs2, tgs2) = MC.update mgs <|
--                 GameSelector.msgSetCurrent curGame
--             (mmg, cmg, tmg) = MC.update m.manageGroups <|
--                 ManageGroups.msgSetGroups groups
--             mm = { m 
--                 | groups = groups
--                 , games = games
--                 , curGame = curGame
--                 , selector = mgs2
--                 , manageGroups = mmg
--                 }
--         in  ( mm
--             , Cmd.map MGameSelector cgs ::
--                 Cmd.map MGameSelector cgs2 ::
--                 Cmd.map MManageGroups cmg ::
--                 list
--             , tgv ++ tgs ++ tgs2 ++ tmg ++ tasks
--             )
--     _ -> (m, list, tasks)
