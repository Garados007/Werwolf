module Game.UI.GameView exposing
    ( GameView
    , GameViewMsg
    , GameViewEvent (..)
    , msgDisposing
    , init
    , view
    , update
    , detector
    )

import Game.Types.Types as Types exposing (..)
import Game.Types.Request as Request exposing (..)
import Game.UI.UserListBox as UserListBox exposing (UserListBox, UserListBoxMsg (..))
import Game.UI.ChatBox as ChatBox exposing 
    (ChatBox, ChatBoxMsg (..), ChatBoxEvent)
import Game.UI.Voting as Voting exposing (..)
import Game.UI.Loading as Loading exposing (loading)
import Game.UI.WaitGameCreation as WaitGameCreation
import Game.UI.GameFinished as GameFinished
import Game.UI.NewGame as NewGame exposing (NewGame, NewGameMsg, NewGameEvent)
import Game.Utils.Language exposing (..)
import Game.Data as Data exposing (..)
import DataDiff.Path as Diff exposing (DetectorPath, Path (..))
import DataDiff.Ex exposing (SingleActionEx (..), ModActionEx (..))
import UnionDict exposing (UnionDict)

import Html exposing (Html,div,text)
import Html.Attributes exposing (class,attribute)
import Dict exposing (Dict)
import Time exposing (Posix)

type GameView = GameView GameViewInfo

type alias GameViewInfo =
    { ownGroupId : GroupId
    , lastVotingChange : Posix
    , lastVoteTime : Posix
    , lastChat : ChatEntryId
    , periods : Periods
    , userListBox : UserListBox
    , chatBox : Maybe ChatBox
    , voting : Maybe Voting.Voting
    , newGame : Maybe NewGame
    , showPlayers : Bool
    , showVotes : Bool
    }

type GameViewViewType
    = ViewLoading
    | ViewInitGame
    | ViewWaitGame
    | ViewNormalGame
    | ViewGuest
    | ViewFinished

type GameViewMsg
    -- public methods
    = Disposing --unregisters all registered requests and other cleanup
    -- Wrapper methods
    | WrapUserListBox UserListBoxMsg
    | WrapChatBox ChatBoxMsg
    | WrapVoting VotingMsg
    | WrapNewGame NewGameMsg
    -- private methodss
    | CreateNewGame
    -- event handler
    | ChangeVotingBox Bool 
    | ChangePlayerBox Bool
    | NoOp
    | CallEvent (List GameViewEvent)
    | PeriodsGameFinished Group
    | PeriodsGameStarted Group GameId
    | PeriodsPhaseChanged Group
    | PeriodsVotingChange GameId (List Types.Voting) Posix
    | PeriodsChatEntryAdded GameId ChatEntryId
    | Batch (List GameViewMsg)
    -- detector handler
    | PathGameFinished
    | PathGameStarted
    | PathPhaseChanged
    | PathVotingChange Posix
    | PathVotingAdded Types.Voting
    | PathChatEntryAdded ChatEntryId

type GameViewEvent
    = Register Request
    | Unregister Request
    | Send Request
    | FetchRoleset String
    | FetchLangset String
    | CallMsg GameViewMsg
    | ReqData (Data -> GameViewMsg)
    | ModData (Data -> Data)
    | IsDisposed
    | RefreshLangList

{-|supports the setting and replacement of periods-}
type alias Periods =
    -- This list is always active while this GameView exists.
    { groupSession : List Request
    -- this periods are active during the whole game session.
    -- This periods will be set if the game starts (or finishes),
    -- while removing the previos list. During a session there is no changement.
    , gameSession : List Request
    -- this list is active during a single game phase.
    , phaseSession : List Request 
    -- the current method to fetch new chats
    , getChats : List Request 
    -- the current method to fetch new votings
    , getVotes : List Request
    }

msgDisposing : GameViewMsg 
msgDisposing = Disposing
 
mapVotingEvent : Voting.VotingEvent -> GameViewEvent 
mapVotingEvent event = case event of 
    Voting.Send r -> Send r 
    Voting.CloseBox -> CallMsg <| ChangeVotingBox False

mapChatBoxEvent : ChatBox.ChatBoxEvent -> GameViewEvent 
mapChatBoxEvent event = case event of 
    ChatBox.ViewUser -> CallMsg <| ChangePlayerBox True 
    ChatBox.ViewVotes -> CallMsg <| ChangeVotingBox True 
    ChatBox.Send r -> Send r 
    ChatBox.ReqData req -> ReqData <| WrapChatBox << req

mapNewGameEvent : NewGame.NewGameEvent -> GameViewEvent 
mapNewGameEvent event = case event of 
    NewGame.FetchLangSet s -> FetchLangset s 
    NewGame.ChangeLeader group user -> Send 
        <| ReqControl
        <| ChangeLeader group user
    NewGame.CreateGame conf -> Send 
        <| ReqControl
        <| StartNewGame conf 
    NewGame.ReqData req -> ReqData <| WrapNewGame << req
    NewGame.ModData mod -> ModData mod
    NewGame.RefreshLangList -> RefreshLangList
    NewGame.FetchOptions opt -> ReqData <| \data ->
        if Dict.member opt data.game.createOptions
        then NoOp
        else CallEvent
            <| List.singleton
            <| Send
            <| ReqInfo
            <| CreateOptions opt

mapUserListBoxEvent : UserListBox.UserListEvent -> GameViewEvent
mapUserListBoxEvent event = case event of 
    UserListBox.CloseBox -> CallMsg <| ChangePlayerBox False

detector : GameView -> DetectorPath Data GameViewMsg
detector (GameView model) = Diff.batch
    <| List.filterMap identity
    [ Just <| detectorInternal <| GameView model
    , Maybe.map 
        (Diff.mapMsg WrapChatBox << ChatBox.detector)
        model.chatBox
    , Maybe.map 
        (Diff.mapMsg WrapNewGame << NewGame.detector)
        model.newGame
    ]

detectorInternal : GameView -> DetectorPath Data GameViewMsg
detectorInternal (GameView model) = Data.pathGameData
    <| Diff.batch
    [ Data.pathGroupData []
        <| Diff.cond (\_ _ g -> g.group.id == model.ownGroupId)
        <| Diff.batch 
        [ Diff.mapData .group
            <| Diff.mapData .currentGame
            <| Diff.maybe
                [ AddedEx <| \_ g -> 
                    if g.finished == Nothing 
                    then PathGameStarted
                    else PathGameFinished
                , AddedEx <| \_ g -> CallEvent
                    <| List.singleton
                    <| FetchLangset g.ruleset
                ]
            <| Diff.batch 
            [ Diff.mapData .finished
                <| Diff.maybe 
                    [ AddedEx <| \_ _ -> PathGameFinished
                    , RemovedEx <| \_ _ -> PathGameStarted
                    ]
                <| Diff.noOp
            , Diff.mapData .phase
                <| Diff.value
                    [ ChangedEx <| \_ _ _ -> PathPhaseChanged ]
            , Diff.mapData .day 
                <| Diff.value 
                    [ ChangedEx <| \_ _ _ -> PathPhaseChanged ]
            , Diff.mapData .ruleset
                <| Diff.value 
                    [ ChangedEx <| \_ _ -> CallEvent 
                        << List.singleton
                        << FetchLangset
                    ]
            ]
        , Data.pathChatData 
                [ AddedEx 
                    (\_ c -> c.chat.voting
                        |> List.map PathVotingAdded
                        |> Batch
                    )
                , AddedEx <| \_ c -> CallEvent
                    <| List.singleton
                    <| Send 
                    <| ReqGet 
                    <| GetChatEntrys
                    <| c.chat.id
                ]
            <| Diff.mapData (.chat >> .voting)
            <| Diff.list (\_ _ -> PathInt)
                [ AddedEx <| \_ v -> PathVotingChange
                    <| maxTime 
                    <| List.filterMap identity
                        [ Just v.created
                        , v.voteStart 
                        , v.voteEnd
                        ]
                , AddedEx <| \_ -> PathVotingAdded
                ]
            <| Diff.batch 
            [ Diff.mapData .created
                <| Diff.value 
                    [ ChangedEx (\_ _ -> PathVotingChange) ]
            , Diff.mapData .voteStart
                <| Diff.maybe 
                    [ AddedEx (\_ -> PathVotingChange) ]
                <| Diff.value 
                    [ ChangedEx (\_ _ -> PathVotingChange) ]
            , Diff.mapData .voteEnd
                <| Diff.maybe 
                    [ AddedEx (\_ -> PathVotingChange) ]
                <| Diff.value 
                    [ ChangedEx (\_ _ -> PathVotingChange) ]
            ]
        , Data.pathChatData []
            <| Data.pathSafeDictString "votes"
                .votes
                [ AddedEx <| \_ -> UnionDict.extract
                    >> Dict.values 
                    >> List.map .date 
                    >> maxTime 
                    >> PathVotingChange
                ]
            <| Data.pathSafeDictInt "single"
                identity
                [ AddedEx <| \_ -> .date >> PathVotingChange
                ]
            <| Diff.mapData .date
            <| Diff.value 
                [ ChangedEx <| \_ _ -> PathVotingChange
                ]
        , Data.pathChatData []
            <| Data.pathSafeDictInt "entry" .entry 
                [ AddedEx <| \_ c -> PathChatEntryAdded c.id
                ]
            <| Diff.noOp
        ] 
    ]

init : GroupId -> (GameView, Cmd GameViewMsg, List GameViewEvent)
init groupId =
    let 
        userListBox = UserListBox.init groupId
        (chatBox, cbCmd, cbTasks) = ChatBox.init groupId
        voting = Voting.init groupId
        info = 
            { ownGroupId = groupId
            , lastVotingChange = Time.millisToPosix 0
            , lastVoteTime = Time.millisToPosix 0
            , lastChat = ChatEntryId 0
            , periods = 
                { groupSession = 
                    [ ReqConv <| LastOnline groupId ]
                , gameSession = []
                , phaseSession = []
                , getChats = []
                , getVotes = []
                }
            , userListBox = userListBox
            , chatBox = Just chatBox
            , voting = Just voting
            , newGame = Nothing
            , showPlayers = False
            , showVotes = False
            }
    in  ( GameView info
        , Cmd.map WrapChatBox cbCmd
        ,   [ Send 
                <| ReqMulti 
                <| Multi 
                    -- todo: check if this request can be moved to game lobby
                    [ ReqGet <| GetGroup groupId
                    , ReqGet <| GetUserFromGroup groupId
                    ]
            , Register <| ReqConv <| LastOnline groupId
            , ReqData <| \data ->
                let group : Maybe Data.GroupData
                    group = getGroup groupId data 
                    isFinished : Bool 
                    isFinished = group
                        |> Maybe.andThen (.group >> .currentGame) 
                        |> Maybe.map 
                            (\g -> case g.finished of 
                                Just _ -> True 
                                Nothing -> False
                            )
                        |> Maybe.withDefault True 
                    votingTime : Posix 
                    votingTime = maxTime 
                        <| List.concatMap 
                            (\c -> 
                                ( Just c
                                    |> getVotings
                                    |> List.concatMap
                                        (\v -> List.filterMap identity
                                            [ Just v.created 
                                            , v.voteStart
                                            , v.voteEnd
                                            ]
                                        )
                                )
                                ++
                                ( c.votes
                                    |> UnionDict.extract
                                    |> Dict.values 
                                    |> List.concatMap 
                                        (UnionDict.extract >> Dict.values)
                                    |> List.map .date

                                )
                            )
                        <| UnionDict.values
                        <| getChats group
                    votings : List Types.Voting 
                    votings = group 
                        |> getChats
                        |> UnionDict.values
                        |> List.concatMap (Just >> getVotings)
                    chatEntry : Maybe ChatEntryId 
                    chatEntry = group 
                        |> getChats
                        |> UnionDict.values 
                        |> List.concatMap 
                            (.entry 
                                >> UnionDict.extract 
                                >> Dict.values 
                            )
                        |> List.map (.id >> Types.chatEntryId)
                        |> List.maximum
                        |> Maybe.map ChatEntryId
                    gameId : Maybe GameId 
                    gameId = group 
                        |> Maybe.andThen (.group >> .currentGame)
                        |> Maybe.map .id
                    roleset : Maybe String 
                    roleset = group 
                        |> Maybe.andThen (.group >> .currentGame)
                        |> Maybe.map .ruleset
                    d_ = Debug.log "GameView:init:roleset" (groupId, roleset)
                in Batch
                    <|  [ if isFinished 
                            then PathGameFinished 
                            else PathGameStarted
                        , PathVotingChange votingTime
                        , Maybe.map2 PeriodsChatEntryAdded gameId chatEntry 
                            |> Maybe.withDefault NoOp
                        , roleset 
                            |> Maybe.map 
                                ( CallEvent 
                                    << List.singleton 
                                    << FetchLangset
                                )
                            |> Maybe.withDefault NoOp
                        ]
                    ++ List.map PathVotingAdded votings

                
            ]
            ++ List.map mapChatBoxEvent cbTasks
        )

update : GameViewMsg -> GameView -> (GameView, Cmd GameViewMsg, List GameViewEvent)
update msg (GameView model) = case msg of
    -- todo : move Disposing code to GameLobby
    Disposing ->
        (GameView model
        , Cmd.none
        , (::) IsDisposed
            <| List.map Unregister 
            <| model.periods.groupSession
            ++ model.periods.gameSession
            ++ model.periods.phaseSession
            ++ model.periods.getChats 
            ++ model.periods.getVotes
        )
    WrapUserListBox wmsg -> 
        let (nm, wcmd, wtasks) = UserListBox.update wmsg model.userListBox
        in  ( GameView { model | userListBox = nm }
            , Cmd.map WrapUserListBox wcmd
            , List.map mapUserListBoxEvent wtasks
            )
    WrapChatBox wmsg -> case model.chatBox of
        Just chatBox ->
            let (nm, wcmd, wtasks) = ChatBox.update wmsg chatBox
            in  ( GameView { model | chatBox = Just nm }
                , Cmd.map WrapChatBox wcmd
                , List.map mapChatBoxEvent wtasks
                )
        Nothing -> (GameView model, Cmd.none, [])
    WrapVoting wmsg -> case model.voting of
        Just voting ->
            let (nm, wcmd, wtasks) = Voting.update wmsg voting
            in  ( GameView { model | voting = Just nm }
                , Cmd.map WrapVoting wcmd
                , List.map mapVotingEvent wtasks
                )
        Nothing -> (GameView model, Cmd.none, [])
    WrapNewGame wmsg -> case model.newGame of
        Just newGame ->
            let (nm, wcmd, wtasks) = NewGame.update wmsg newGame
            in  ( GameView { model | newGame = Just nm }
                , Cmd.map WrapNewGame wcmd
                , List.map mapNewGameEvent wtasks
                )
        Nothing -> (GameView model, Cmd.none, [])
    CreateNewGame -> 
        let (nm,wtask) = NewGame.init model.ownGroupId
        in  ( GameView { model | newGame = Just nm } 
            , Cmd.none
            , (::) 
                (ReqData <| \data ->
                    if data.game.installedTypes == Nothing
                    then CallEvent 
                        <| List.singleton
                        <| Send 
                        <| ReqInfo InstalledGameTypes
                    else NoOp
                ) 
                <| List.map mapNewGameEvent wtask
            )
    ChangeVotingBox vis ->
        ( GameView { model | showVotes = vis }
        , Cmd.none 
        , []
        )
    ChangePlayerBox vis ->
        ( GameView { model | showPlayers = vis }
        , Cmd.none
        , []
        )
    NoOp -> ( GameView model, Cmd.none, [])
    CallEvent events -> ( GameView model, Cmd.none, events)
    PathGameFinished -> 
        ( GameView
            { model
            | lastVotingChange = Time.millisToPosix 0
            , lastVoteTime = Time.millisToPosix 0
            , lastChat = ChatEntryId 0
            , chatBox = Nothing
            , voting = Nothing
            }
        , Cmd.none
        , [ ReqData 
                (\data -> getGroup model.ownGroupId data
                    |> Maybe.map (.group >> PeriodsGameFinished)
                    |> Maybe.withDefault NoOp
                )
            ]
        )
    PeriodsGameFinished group ->
        let periodsPhase = requestUpdatedGroup group 
            send = 
                [ ReqGet <| GetUserFromGroup model.ownGroupId
                ]
        in  ( GameView --todo: insert new game
                { model
                | periods = model.periods |> \periods -> 
                    { periods 
                    | gameSession = []
                    , phaseSession = [ periodsPhase ]
                    , getChats = []
                    , getVotes = []
                    }
                }
            , Cmd.none 
            , (++) (List.map Send send)
                <| List.map Unregister
                <| model.periods.gameSession 
                ++ model.periods.phaseSession
                ++ model.periods.getChats 
                ++ model.periods.getVotes
            )
    PathGameStarted ->
        ( GameView 
            { model
            | lastVotingChange = Time.millisToPosix 0
            , lastVoteTime = Time.millisToPosix 0
            , lastChat = ChatEntryId 0
            , newGame = Nothing
            }
        , Cmd.none
        ,   [ ReqData <| \data ->
                let group = getGroup model.ownGroupId data
                    game = getGameId group 
                in Maybe.map2 PeriodsGameStarted 
                        (Maybe.map .group group) game 
                    |> Maybe.withDefault NoOp
            ]
        )
    PeriodsGameStarted group game ->
        let periodsPhase = requestUpdatedGroup group 
            periodsVotes = requestChangedVotings 
                game model.lastVotingChange
            periodsChat = requestChatEntrys game model.lastChat
            send = 
                [ ReqGet <| GetChatRooms game 
                , ReqGet <| GetUserFromGroup model.ownGroupId
                ]
            (cbm, cbc, cbt) = ChatBox.init model.ownGroupId 
            vm = Voting.init model.ownGroupId
        in  ( GameView 
                { model
                | periods = model.periods |> \periods -> 
                    { periods 
                    | gameSession = []
                    , phaseSession = [ periodsPhase ]
                    , getChats = [ periodsChat ]
                    , getVotes = [ periodsVotes ]
                    }
                , chatBox = Just cbm
                , voting = Just vm
                }
            , Cmd.map WrapChatBox cbc
            , List.map Send send
                ++ ( List.map Unregister
                    <| model.periods.gameSession 
                    ++ model.periods.phaseSession
                    ++ model.periods.getChats 
                    ++ model.periods.getVotes
                )
                ++ List.map mapChatBoxEvent cbt
                ++ ( Maybe.map .ruleset group.currentGame
                    |> Maybe.map (FetchRoleset >> List.singleton)
                    |> Maybe.withDefault []
                    )
            )
    PathPhaseChanged ->
        ( GameView
            { model 
            | newGame = Nothing
            }
        , Cmd.none 
        , [ ReqData 
                (\data -> getGroup model.ownGroupId data
                    |> Maybe.map (.group >> PeriodsPhaseChanged)
                    |> Maybe.withDefault NoOp
                )
            ]
        )
    PeriodsPhaseChanged group ->
        let periodsPhase = requestUpdatedGroup group 
        in  ( GameView 
                { model
                | periods = model.periods |> \periods -> 
                    { periods | phaseSession = [ periodsPhase ] }
                }
            , Cmd.none 
            , List.map Unregister model.periods.phaseSession
            )
    PathVotingChange time ->
        ( GameView model 
        , Cmd.none 
        , List.singleton
            <| ReqData
            (\data -> 
                let group : Maybe Data.GroupData 
                    group = getGroup model.ownGroupId data
                    votings : List Types.Voting
                    votings = group 
                        |> getChats 
                        |> UnionDict.values
                        |> List.concatMap (Just >> getVotings) 
                    game : Maybe GameId
                    game = getGameId group
                in case game of 
                    Just id -> PeriodsVotingChange id votings time
                    Nothing -> NoOp
            )
        )
    PeriodsVotingChange game votings time ->
        let rtime = maxTime [ time, model.lastVotingChange ]
            periodsVotes = requestChangedVotings game rtime
                :: List.map 
                    (\v -> requestNewVotes v model.lastVotingChange)
                    votings
        in  ( GameView 
                { model
                | lastVotingChange = rtime
                , periods = model.periods |> \periods -> 
                    { periods 
                    | getVotes = periodsVotes
                    }
                }
            , Cmd.none 
            , (++) (List.map Register periodsVotes)
                <| List.map Unregister
                <| model.periods.getVotes
            )
    PathVotingAdded voting ->
        let periodsVotes = [ requestNewVotes voting model.lastVotingChange ]
                |> List.filter 
                    (\v -> not <| List.member v model.periods.getVotes )
        in  ( GameView 
                { model
                | periods = model.periods |> \periods -> 
                    { periods 
                    | getVotes = periods.getVotes ++ periodsVotes
                    }
                }
            , Cmd.none 
            , List.map Register periodsVotes
            )
    Batch list -> List.foldr 
        (\smsg (mod, cmds, tasks) ->
            let (m, c, t) = update smsg mod
            in (m, c :: cmds, t ++ tasks)
        )
        (GameView model, [], [])
        list 
        |> \(m, c, t) -> (m, Cmd.batch c, t)
    PathChatEntryAdded cid ->
        ( GameView model 
        , Cmd.none 
        , List.singleton
            <| ReqData
            (\data -> getGroup model.ownGroupId data 
                |> getGameId
                |> Maybe.map (\id -> PeriodsChatEntryAdded id cid)
                |> Maybe.withDefault NoOp
            )
        )
    PeriodsChatEntryAdded game id ->
        let mid = [ id, model.lastChat ]
                |> List.map Types.chatEntryId
                |> List.maximum
                |> Maybe.map ChatEntryId 
                |> Maybe.withDefault id
            periodsChats = requestChatEntrys game mid
        in  ( GameView 
                { model
                | lastChat = mid
                , periods = model.periods |> \periods -> 
                    { periods 
                    | getChats = [ periodsChats ]
                    }
                }
            , Cmd.none 
            , (::) (Register periodsChats)
                <| List.map Unregister
                <| model.periods.getVotes
            )

requestUpdatedGroup : Group -> Request
requestUpdatedGroup group =
    let groupMaxTime = maxTime 
            <| List.filterMap identity
                [ Just group.created
                , group.lastTime
                , Maybe.map .started group.currentGame
                , Maybe.andThen .finished group.currentGame
                ]
        phaseDay = Maybe.map 
            (\g -> (g.phase, g.day)) 
            group.currentGame
    in ReqConv 
        <| GetUpdatedGroup
        <| GroupVersion
            group.id 
            groupMaxTime 
            group.leader
            phaseDay

requestChangedVotings : GameId -> Posix -> Request
requestChangedVotings game lastChange =
    ReqConv <| GetChangedVotings game lastChange

requestChatEntrys : GameId -> ChatEntryId -> Request
requestChatEntrys gameId lastId =
    ReqConv <| GetAllNewChatEntrys gameId <| lastId

requestNewVotes : Types.Voting -> Posix -> Request
requestNewVotes voting lastChange = 
    ReqConv <| GetNewVotes voting.chat voting.voteKey lastChange

maxTime : List Posix -> Posix 
maxTime = List.map Time.posixToMillis
    >> List.maximum
    >> Maybe.withDefault 0 
    >> Time.millisToPosix

hasPlayer : Data -> Data.GroupData -> Bool 
hasPlayer data group = case data.game.ownId of
    Just id -> group.user
        |> List.map .user 
        |> List.member id 
    Nothing -> False

getViewType : Data -> GameViewInfo -> GameViewViewType
getViewType data info =
    case getGroup info.ownGroupId data of
        Nothing -> 
            let d_ = Debug.log "getViewType" <| Tuple.pair
                    info.ownGroupId data
            in ViewLoading
        Just group -> case group.group.currentGame of
            Nothing ->
                if Just group.group.leader == data.game.ownId
                then case info.newGame of
                    Just _ -> ViewInitGame
                    Nothing -> ViewWaitGame
                else ViewWaitGame
            Just game -> case game.finished of
                Just _ -> case info.newGame of
                    Just _ -> ViewInitGame
                    Nothing -> ViewFinished
                Nothing ->
                    if hasPlayer data group
                    then ViewNormalGame
                    else ViewGuest

view : Data -> LangLocal -> GameView -> Html GameViewMsg
view data lang (GameView info) = case getViewType data info of
    ViewLoading -> loading
    ViewInitGame -> div 
        [ class "w-box-game-view"
        , attribute "data-view" 
            <| Debug.toString 
            <| getViewType data info 
        ] 
        [ div 
            [ class <| (++) "w-box-panel w-box-player "
                <| if info.showPlayers then "visible" else ""
            ]
            [ Html.map WrapUserListBox
                <| UserListBox.view data lang info.userListBox 
            ]
        , case info.newGame of
            Just newGame -> Html.map WrapNewGame 
                <| NewGame.view data lang newGame
            Nothing -> div [] []
        ]
    ViewWaitGame -> div 
        [ class "w-box-game-view"
        , attribute "data-view" 
            <| Debug.toString 
            <| getViewType data info 
        ] 
        [ div 
            [ class <| (++) "w-box-panel w-box-player " <| 
                if info.showPlayers then "visible" else ""
            ]
            [ Html.map WrapUserListBox
                <| UserListBox.view data lang info.userListBox 
            ]
        , WaitGameCreation.view lang
        ]
    ViewNormalGame -> div 
        [ class "w-box-game-view"
        , attribute "data-view" 
            <| Debug.toString 
            <| getViewType data info 
        ] 
        [ div 
            [ class <| (++) "w-box-panel w-box-player" <| 
                if info.showPlayers then " visible" else ""
            ]
            [ Html.map WrapUserListBox 
                <| UserListBox.view data lang info.userListBox 
            ]
        , Html.map WrapChatBox <| case info.chatBox of
            Just cb -> ChatBox.view data lang cb
            Nothing -> Debug.todo "GameView:view:ViewNormalGame - chatBox should exists"
        ,div 
            [ class <| (++) "w-box-panel w-box-voting" <| 
                if info.showVotes then " visible" else ""
            ]
            [ Html.map WrapVoting <| case info.voting of
                Just v -> Voting.view data lang v
                Nothing -> Debug.todo "GameView:view:ViewNormalGame - voting should exists"
            ]
        --, Html.text <| Debug.toString info
        ]
    ViewGuest -> div 
        [ class "w-box-game-view"
        , attribute "data-view" 
            <| Debug.toString 
            <| getViewType data info 
        ] 
        [ div 
            [ class <| (++) "w-box-panel w-box-player " <| 
                if info.showPlayers then "visible" else ""
            ]
            [ Html.map WrapUserListBox
                <| UserListBox.view data lang info.userListBox 
            ]
        , Html.map WrapChatBox <| case info.chatBox of
            Just cb -> ChatBox.view data lang cb
            Nothing -> Debug.todo "GameView:view:ViewGuest - chatBox should exists"
        ]
    ViewFinished -> div 
        [ class "w-box-game-view"
        , attribute "data-view" 
            <| Debug.toString 
            <| getViewType data info 
        ] 
        [ div 
            [ class <| (++) "w-box-panel w-box-player " <| 
                if info.showPlayers then "visible" else ""
            ]
            [ Html.map WrapUserListBox
                <| UserListBox.view data lang info.userListBox 
            ]
        ,   let group = getGroup info.ownGroupId data 
                    |> Maybe.map .group
                leader = Maybe.map .leader group == data.game.ownId
                game = Maybe.andThen .currentGame group
            in Maybe.map
                (\g -> GameFinished.view lang leader g CreateNewGame)
                game
                |> Maybe.withDefault (text "")
        ]
