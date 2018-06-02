module Game.UI.GameView exposing
    ( GameView
    , GameViewMsg
        ( RegisterNetwork
        , UnregisterNetwork
        , SendNetwork
        , FetchRulesetLang
        , SetConfig
        , SetLang
        , Manage
        , Disposing
        )
    , init
    , update
    , view
    , subscriptions
    )

import ModuleConfig as MC exposing (..)

import Game.Types.Types exposing (..)
import Game.Types.Changes exposing (..)
import Game.Types.CreateOptions as CreateOptions exposing (..)
import Game.Utils.Network exposing (Request)
import Game.Types.Request as Request exposing (..)
import Game.UI.UserListBox as UserListBox exposing (UserListBox, UserListBoxMsg (..))
import Game.UI.ChatBox as ChatBox exposing 
    (ChatBox, ChatBoxMsg (..), ChatBoxDef, ChatBoxEvent, chatBoxModule)
import Game.UI.Voting as Voting exposing (..)
import Game.UI.Loading as Loading exposing (loading)
import Game.UI.WaitGameCreation as WaitGameCreation
import Game.UI.GameFinished as GameFinished
import Game.UI.NewGame as NewGame exposing (NewGameDef,newGameModule,NewGameMsg,NewGameEvent)
import Game.Configuration exposing (..)
import Game.Utils.Language exposing (..)
import Config exposing (..)

import Html exposing (Html,div,text)
import Html.Attributes exposing (class,attribute)
import Task exposing (succeed, perform)
import Dict exposing (Dict)

type GameView = GameView GameViewInfo

type alias GameViewInfo =
    { config : LangConfiguration
    , lang : LangGlobal
    , group : Maybe Group
    , hasPlayer : Bool
    , ownUserId : Int
    , lastVotingChange : Int
    , lastVoteTime : Int
    , chats : Dict ChatId Chat
    , lastChat : Dict ChatId Int
    , user : List User
    , periods : List Request
    , entrys : Dict ChatId (Dict Int ChatEntry)
    , votes : Dict ChatId (Dict VoteKey (Dict UserId Vote))
    , installedTypes : Maybe (List String)
    , createOptions : Dict String CreateOptions
    , rolesets : Dict String (List String)
    , userListBox : UserListBox
    , chatBox : Maybe (ChatBoxDef Int EventMsg)
    , voting : Maybe (VotingDef EventMsg)
    , newGame : Maybe (NewGameDef EventMsg)
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
    -- public events
    = RegisterNetwork Request
    | UnregisterNetwork Request
    | SendNetwork Request
    | FetchRulesetLang String
    -- public methods
    | Manage (List Changes)
    | SetConfig Configuration
    | SetLang LangGlobal
    | Disposing --unregisters all registered requests and other cleanup
    -- Wrapper methods
    | WrapUserListBox UserListBoxMsg
    | WrapChatBox ChatBoxMsg
    | WrapVoting VotingMsg
    | WrapNewGame NewGameMsg
    -- private methods
    | PushConfig ()
    | CreateNewGame

type alias ChangeVar a =
    { new : a
    , register : List Request
    , unregister : List Request
    , send : List Request
    }

type EventMsg
    = SendMes Request
    | ViewUser
    | ViewVotes
    | PushInstalledTypes
    | FetchLangSet String

combine : ChangeVar a -> ChangeVar a -> ChangeVar a
combine a b = ChangeVar b.new 
    (a.register ++ b.register) 
    (a.unregister ++ b.unregister)
    (a.send ++ b.send)

init : Int -> Int -> (GameView, Cmd GameViewMsg)
init groupId ownUserId =
    let 
        own = perform SendNetwork <| succeed <| initRequest groupId ownUserId
        config = LangConfiguration empty <|
            createLocal (newGlobal lang_backup) Nothing 
        (userListBox, ulbCmd) = UserListBox.init config
        (chatBox, cbCmd, cbTasks) = chatBoxModule handleChatBox (config, groupId)
        (voting, vCmd, vTasks) = votingModule handleVoting (config, ownUserId)
        info = 
            { config = config
            , lang = newGlobal lang_backup
            , group = Nothing
            , hasPlayer = False
            , ownUserId = ownUserId
            , lastVotingChange = 0
            , lastVoteTime = 0
            , chats = Dict.empty
            , lastChat = Dict.empty
            , user = []
            , periods = []
            , entrys = Dict.empty
            , votes = Dict.empty
            , installedTypes = Nothing
            , createOptions = Dict.empty
            , rolesets = Dict.empty
            , userListBox = userListBox
            , chatBox = Just chatBox
            , voting = Just voting
            , newGame = Nothing
            , showPlayers = False
            , showVotes = False
            }
        (ninfo, eventCmd) = handleEvent info (cbTasks ++ vTasks)
    in  ( GameView ninfo
        , Cmd.batch 
            [ own
            , Cmd.map WrapUserListBox ulbCmd
            , Cmd.map WrapChatBox cbCmd
            , Cmd.map WrapVoting vCmd
            , Cmd.batch eventCmd
            ]
        )

initRequest : Int -> Int -> Request
initRequest groupId ownUserId =
    RespMulti <| Multi 
        [ RespGet <| GetGroup groupId
        , RespGet <| GetUserFromGroup groupId
        ]

handleChatBox : ChatBoxEvent -> List EventMsg
handleChatBox event = case event of
    ChatBox.ViewUser -> [ ViewUser ]
    ChatBox.ViewVotes -> [ ViewVotes ]
    ChatBox.Send request -> [ SendMes request ]

handleVoting : VotingEvent -> List EventMsg
handleVoting event = case event of
    Voting.Send request -> [ SendMes request ]

handleNewGame : NewGameEvent -> List EventMsg
handleNewGame event = case event of
    NewGame.RequestInstalledTypes -> [ PushInstalledTypes ]
    NewGame.FetchLangSet ruleset -> [ FetchLangSet ruleset ]
    NewGame.ChangeLeader group target -> 
        [ SendMes <| RespControl <| ChangeLeader group target ]
    NewGame.CreateGame config ->
        [ SendMes <| RespControl <| StartNewGame config ]

handleEvent : GameViewInfo -> List EventMsg -> (GameViewInfo, List (Cmd GameViewMsg))
handleEvent = changeWithAll2
    (\info event -> case event of
        SendMes request ->
            ( info
            , Task.perform SendNetwork <| Task.succeed request
            )
        ViewUser ->
            ( { info | showPlayers = not info.showPlayers }
            , Cmd.none
            )
        ViewVotes ->
            ( { info | showVotes = not info.showVotes }
            , Cmd.none
            )
        PushInstalledTypes ->
            ( info
            , case info.installedTypes of
                Just it -> Task.perform WrapNewGame <| Task.succeed <|
                    NewGame.SetInstalledTypes it
                Nothing -> Task.perform SendNetwork <| Task.succeed <|
                    RespInfo InstalledGameTypes
            )
        FetchLangSet ruleset ->
            ( info
            , Task.perform FetchRulesetLang <| Task.succeed ruleset
            )
    )

justMcUpdate : (a -> msg -> (a, Cmd msg, List ev)) -> Maybe a -> msg -> (Maybe a, Cmd msg, List ev)
justMcUpdate fc model msg = case model of
    Just m -> (\(m,c,l) -> (Just m, c, l)) <| fc m msg
    Nothing -> (Nothing, Cmd.none, [])

update : GameViewMsg -> GameView -> (GameView, Cmd GameViewMsg)
update msg (GameView model) = case msg of
    Manage changes ->
        let
            changed_ = performUpdate updateGroup model changes
            r2 = Tuple.first <| removeDuplicates changed_.register model.periods
            (rr, ru) = removeDuplicates r2 changed_.unregister
            changed = { changed_ 
                | register = removeDoubles rr
                , unregister = removeDoubles changed_.unregister
                }
            req1 = flip List.filter model.periods 
                <| not << flip List.member changed.unregister
            req2 = List.append req1 changed.register
            cmd = List.concat
                [ List.map (Task.perform UnregisterNetwork << Task.succeed)
                    changed.unregister
                , List.map (Task.perform RegisterNetwork << Task.succeed)
                    changed.register
                , List.map (Task.perform SendNetwork << Task.succeed)
                    changed.send
                ]
            new = changed.new
            nm = { new | periods = req2 }
            cmd_ulb = getChanges_UserListBox model nm
            cmd_cb = getChanges_ChatBox model nm
            cmd_v = getChanges_Voting model nm
            cmd_conf = getChanges_Config model nm
            cmd_ng = getChanges_NewGame model nm
            (tm, cmd_g) = performChanges_Group model nm
        in  (GameView tm
            , Cmd.batch (cmd ++ 
                [ cmd_ulb
                , cmd_cb
                , cmd_v
                , cmd_conf
                , cmd_ng
                , cmd_g
                ])
            )
    Disposing ->
        (GameView model
        , Cmd.batch <| List.map (Task.perform UnregisterNetwork << Task.succeed) model.periods
        )
    WrapUserListBox wmsg ->
        let
            (nm, wcmd) = UserListBox.update wmsg model.userListBox
        in  ( GameView { model | userListBox = nm }
            , Cmd.map WrapUserListBox wcmd
            )
    WrapChatBox wmsg -> case model.chatBox of
        Just chatBox ->
            let (nm, wcmd, wtasks) = MC.update chatBox wmsg
                (tm, tcmd) = handleEvent { model | chatBox = Just nm } wtasks
            in  ( GameView tm
                , Cmd.batch <| (Cmd.map WrapChatBox wcmd) :: tcmd
                )
        Nothing -> (GameView model, Cmd.none)
    WrapVoting wmsg -> case model.voting of
        Just voting ->
            let (nm, wcmd, wtasks) = MC.update voting wmsg
                (tm, tcmd) = handleEvent { model | voting = Just nm } wtasks
            in  ( GameView tm
                , Cmd.batch <| (Cmd.map WrapVoting wcmd) :: tcmd
                )
        Nothing -> (GameView model, Cmd.none)
    WrapNewGame wmsg -> case model.newGame of
        Just newGame ->
            let (nm, wcmd, wtasks) = MC.update newGame wmsg
                (tm, tcmd) = handleEvent { model | newGame = Just <| nm } wtasks
            in  ( GameView tm
                , Cmd.batch <| (Cmd.map WrapNewGame wcmd) :: tcmd
                )
        Nothing -> (GameView model, Cmd.none)
    SetConfig config ->
        let oc = model.config
            nc = { oc | conf = config }
        in  ( GameView { model | config = nc }
            , Task.perform PushConfig <| Task.succeed ()
            )
    SetLang lang ->
        let oc = model.config
            local = createLocal lang <|
                    Maybe.map .ruleset <|
                    Maybe.andThen .currentGame <|
                    model.group
            nc = { oc | lang = local }
        in  ( GameView { model | config = nc, lang = lang }
            , Task.perform PushConfig <| Task.succeed ()
            )
    PushConfig () ->
        let cgs = case model.newGame of
                Nothing ->
                    Maybe.map .ruleset <| Maybe.andThen .currentGame <| model.group
                Just newGame -> getModule newGame |> NewGame.getActiveRuleset
            local = if cgs /= getGameset model.config.lang
                then createLocal model.lang cgs
                else model.config.lang
            oc = model.config
            nc = { oc 
                | lang = local
                    |> flip updateUser model.user
                    |> flip updateChats model.chats
                }
            model1 = { model | config = nc }
            (nm1, wcmd1) = UserListBox.update (UpdateConfig nc) model1.userListBox
            (nm2, wcmd2, wtasks2) = justMcUpdate MC.update model.chatBox (ChatBox.SetConfig nc)
            (nm3, wcmd3, wtasks3) = justMcUpdate MC.update model.voting (Voting.SetConfig nc)
            (nm4, wcmd4, wtasks4) = justMcUpdate MC.update model.newGame (NewGame.SetConfig nc)
            model2 = { model1 
                | userListBox = nm1
                , chatBox = nm2 
                , voting = nm3
                , newGame = nm4
                }
            (tm,tcmd) = handleEvent model2 (wtasks2 ++ wtasks3 ++ wtasks4)
        in  ( GameView tm
            , Cmd.batch 
                ([ Cmd.map WrapUserListBox wcmd1 
                , Cmd.map WrapChatBox wcmd2
                , Cmd.map WrapVoting wcmd3
                , Cmd.map WrapNewGame wcmd4
                ] ++ tcmd)
            )
    CreateNewGame ->
        let group = case model.group of
                Just g -> g
                Nothing -> Debug.crash "GameView:update:CreateNewGame - no group is set, new Game cant be created"
            (nm,wcmd,wtask) = newGameModule handleNewGame (model.config, group)
            (tm,tcmd) = handleEvent { model | newGame = Just nm } wtask
        in  ( GameView tm
            , Cmd.batch <| (Cmd.map WrapNewGame wcmd) :: tcmd
            )
    FetchRulesetLang _ ->
        ( GameView model, Task.perform PushConfig <| Task.succeed ())

    _ -> (GameView model, Cmd.none)

removeDuplicates : List a -> List a -> (List a, List a)
removeDuplicates a b =
    let filter : List a -> a -> Bool
        filter = \c v -> not <| List.member v c
        ra = List.filter (filter b) a
        rb = List.filter (filter a) b
    in (ra, rb)

removeDoubles : List a -> List a
removeDoubles list =
    case list of
        [] -> []
        c :: cs ->
            if List.member c cs
            then removeDoubles cs
            else c :: (removeDoubles cs)

performUpdate : (a -> Changes -> ChangeVar a) -> a -> List Changes -> ChangeVar a
performUpdate updater info changes =
    case changes of
        [] -> ChangeVar info [] [] []
        c :: cs ->
            let
                change1 = updater info c
                change2 = performUpdate updater change1.new cs
            in combine change1 change2

pushUpdate : (a -> b -> a) -> a -> List b -> a
pushUpdate f init list =
    case list of
        [] -> init
        l :: ls -> pushUpdate f (f init l) ls

groupFinished : Group -> Bool
groupFinished group = case group.currentGame of
    Nothing -> True
    Just game -> case game.finished of
        Nothing -> False
        Just _ -> True

updateGroup : GameViewInfo -> Changes -> ChangeVar GameViewInfo
updateGroup info change = 
    case change of
        CGroup group ->
            let finished = groupFinished group
                changefinished = case info.group of
                    Just g -> xor finished <| groupFinished g
                    Nothing -> True
                cleanUser : List User -> List User
                cleanUser = List.map (\u -> { u | player = Nothing})
                filterPeriods : List Request -> List Request
                filterPeriods = List.filter
                    (\req -> case req of
                        RespConv (GetNewVotes _ _ _) -> True
                        RespConv (GetNewChatEntrys _ _) -> True
                        RespConv (GetChangedVotings _ _) -> True
                        _ -> False
                    )
                newModel =
                    if changefinished
                    then { info
                        | group = Just group
                        , hasPlayer = False
                        , lastVotingChange = 0
                        , lastVoteTime = 0
                        , chats = Dict.empty
                        , lastChat = Dict.empty
                        , entrys = Dict.empty
                        , votes = Dict.empty
                        , user = cleanUser info.user
                        , newGame = if (group.leader == info.ownUserId) && finished
                            then info.newGame
                            else Nothing
                        }
                    else { info 
                        | group = Just group
                        , newGame = if group.leader == info.ownUserId
                            then info.newGame
                            else Nothing 
                        }
                nperiods = List.filterMap identity 
                        [ Just <| requestUpdatedGroup group
                        , if finished
                            then Nothing
                            else requestChangedVotings group info.lastVotingChange
                        , if info.group == Nothing
                            then Just <| RespConv <| LastOnline group.id
                            else Nothing
                        ]
                (rperiods, send) = case info.group of
                    Nothing -> ([], List.filterMap identity 
                        [ Maybe.map
                            (\game -> RespGet <| GetChatRooms game.id)
                            group.currentGame
                        ])
                    Just old -> 
                        ( List.filterMap identity  <| List.concat
                            [ List.singleton <| Just <| requestUpdatedGroup old
                            , List.singleton <| requestChangedVotings old info.lastVotingChange
                            , if changefinished && finished
                                then List.map Just <| filterPeriods info.periods
                                else []
                            ]
                        , List.filterMap identity 
                            [ if (old /= group) && (not finished)
                                then Maybe.map
                                    (\game -> RespGet <| GetChatRooms game.id)
                                    group.currentGame
                                else Nothing
                            , if changefinished
                                then Just <| RespGet <| GetUserFromGroup group.id
                                else Nothing
                            ]
                        )
                
            in ChangeVar newModel nperiods rperiods send
        CUser user -> ChangeVar
            { info
            | user = (::) user <| List.filter ((./=) .user user) info.user
            , hasPlayer =
                if user.user == info.ownUserId
                then user.player /= Nothing
                else info.hasPlayer
            }
            [] [] []
        CLastOnline list ->
            let el = List.map .user info.user
                ul = List.map Tuple.first list
                nl = List.filter (not << flip List.member el) ul
                rl = List.filter (not << flip List.member ul) el
            in ChangeVar
                { info
                | user = List.filterMap
                    (\user -> if not <| List.member user.user rl
                        then Just <| pushUpdate
                            (\u (id, time) ->
                                if u.user == id
                                then 
                                    let
                                        s1 = u.stats
                                        s2 = { s1 | lastOnline = time }
                                    in { u | stats = s2}
                                else u
                            )
                            user
                            list
                        else Nothing
                    )
                    info.user
                } [] []
                ( case info.group of
                    Just group -> if List.length nl /= 0
                        then [ RespGet <| GetUserFromGroup group.id ]
                        else []
                    Nothing -> []
                )
        CChat chat -> 
            let 
                finished = Maybe.withDefault True <| Maybe.map groupFinished info.group
                old = Dict.get chat.id info.chats
                oldTime = Maybe.withDefault 0 <| 
                    Dict.get chat.id info.lastChat
                time = max info.lastVotingChange <| 
                    getNewestVotingTime chat
                dict : Dict VoteKey (Dict UserId Vote)
                dict = case Dict.get chat.id info.votes of
                    Just d -> modifyVotes d chat
                    Nothing -> modifyVotes Dict.empty chat
            in ChangeVar
                { info
                | chats = Dict.insert chat.id chat info.chats
                , lastChat = Dict.insert chat.id oldTime info.lastChat
                , lastVotingChange = time
                , entrys = Dict.insert chat.id Dict.empty info.entrys
                , votes = Dict.insert chat.id dict info.votes
                } 
                (if finished then [] else List.append
                    [ requestChatEntrys chat.id oldTime ]
                    <| requestNewVotes chat info.lastVoteTime
                )
                ( List.append
                    ( Maybe.withDefault []
                        <| Maybe.map 
                            (List.singleton << 
                                flip requestChatEntrys oldTime
                                << .id) 
                            old
                    )
                    <| Maybe.withDefault [] 
                    <| Maybe.map (flip requestNewVotes info.lastVoteTime) old
                )
                []
        CChatEntry entry -> case Dict.get entry.chat info.entrys of
            Just dict ->
                let
                    oldTime = Dict.get entry.chat info.lastChat
                    time = max entry.sendDate <| Maybe.withDefault 1 oldTime
                    nd = Dict.insert entry.id entry dict
                in ChangeVar
                    { info
                    | lastChat = Dict.insert entry.chat time info.lastChat
                    , entrys = Dict.insert entry.chat nd info.entrys
                    }
                    (if oldTime /= Just time
                     then [ requestChatEntrys entry.chat time ]
                     else []
                    )
                    (if oldTime /= Just time
                     then [ requestChatEntrys entry.chat <| Maybe.withDefault 0 oldTime ]
                     else []
                    )
                    []
            Nothing -> ChangeVar info [] [] []
        CVote vote ->
            case Dict.get vote.setting info.votes of
                Nothing -> ChangeVar info [] [] []
                Just v1 ->
                    case Dict.get vote.voteKey v1 of
                        Nothing -> ChangeVar info [] [] []
                        Just v2 ->ChangeVar
                            { info
                            | votes = Dict.insert 
                                vote.setting
                                ( Dict.insert 
                                    vote.voteKey
                                    (Dict.insert vote.voter vote v2)
                                    v1
                                )
                                info.votes
                            } [] [] []
        CVoting voting ->
            case Dict.get voting.chat info.chats of
                Nothing -> ChangeVar info [] [] []
                Just chat ->
                    let
                        nc = { chat
                            | voting = replace 
                                (\v -> v.chat /= voting.chat || v.voteKey /= v.voteKey)
                                voting chat.voting
                            }
                    in ChangeVar
                        { info
                        | chats = Dict.insert nc.id nc info.chats
                        } 
                        (if voting.voteEnd == Nothing && voting.voteStart /= Nothing
                        then [ requestNewVotesS voting info.lastVoteTime ]
                        else []
                        )
                        (if voting.voteEnd /= Nothing
                        then [ requestNewVotesS voting info.lastVoteTime ]
                        else []
                        )
                        []
        CGame game -> case info.group of
            Nothing -> ChangeVar info [] [] []
            Just g -> updateGroup info <| CGroup { g | currentGame = Just game }
        CInstalledGameTypes list -> ChangeVar
            { info | installedTypes = Just list } [] [] []
        CCreateOptions key options -> ChangeVar
            { info | createOptions = Dict.insert key options info.createOptions } [] [] []
        CRolesets key list -> ChangeVar
            { info | rolesets = Dict.insert key list info.rolesets } [] [] []
        _ -> ChangeVar info [] [] []

performChanges_Group : GameViewInfo -> GameViewInfo -> (GameViewInfo, Cmd GameViewMsg)
performChanges_Group old new = case new.group of
    Just group ->
        let finished = groupFinished group
            changefinished = case old.group of
                Just g -> xor finished <| groupFinished g
                Nothing -> True
            firstJust = \(m,c,t) -> (Just m,c,t)
            (chatBox, cbCmd, cbTasks) = if changefinished && (not finished)
                then firstJust <| chatBoxModule handleChatBox (new.config, group.id)
                else if changefinished && finished
                    then (Nothing, Cmd.none, [])
                    else (new.chatBox, Cmd.none, [])
            (voting, vCmd, vTasks) = if changefinished && (not finished)
                then firstJust <| votingModule handleVoting (new.config, new.ownUserId)
                else if changefinished && finished
                    then (Nothing, Cmd.none, [])
                    else (new.voting, Cmd.none, [])
            (newModel, eCmd) = handleEvent
                { new | chatBox = chatBox, voting = voting } 
                (cbTasks ++ vTasks)
        in (newModel, Cmd.batch <| [ Cmd.map WrapChatBox cbCmd, Cmd.map WrapVoting vCmd] ++ eCmd)
    Nothing -> (new, Cmd.none)

getChanges_UserListBox : GameViewInfo -> GameViewInfo -> Cmd GameViewMsg
getChanges_UserListBox old new =
    Cmd.batch <| List.map (Cmd.map WrapUserListBox) <| List.filterMap identity
        [ if old.user /= new.user
            then Just <| perform UpdateUser <| succeed new.user
            else Nothing
        , if old.chats /= new.chats
            then Just <| perform UpdateChats <| succeed new.chats
            else Nothing
        , if old.group == new.group
            then Nothing
            else case new.group of
                Nothing -> Nothing
                Just group -> case group.currentGame of
                    Nothing -> Nothing
                    Just game ->
                        Just <| perform UpdateRuleset <| succeed game.ruleset
        ]

getChanges_ChatBox : GameViewInfo -> GameViewInfo -> Cmd GameViewMsg
getChanges_ChatBox old new =
    Cmd.batch <| List.map (Cmd.map WrapChatBox) <| List.filterMap identity
        [ if old.entrys /= new.entrys
            then Just <| perform AddChats <| Task.succeed <|
                List.filter (\ce ->
                    let time = Maybe.withDefault -1 <| 
                            Dict.get ce.chat old.lastChat
                    in ce.sendDate > time
                ) <|
                List.concat <| 
                List.map Dict.values <| Dict.values new.entrys
            else Nothing
        , if old.user /= new.user
            then Just <| perform ChatBox.SetUser <| succeed <| Dict.fromList <|
                List.map (\user -> (user.user, user.stats.name)) new.user
            else Nothing
        , if old.chats /= new.chats
            then Just <| perform ChatBox.SetRooms <| succeed <| new.chats
            else Nothing
        , if (Maybe.andThen .currentGame old.group) /= (Maybe.andThen .currentGame new.group)
            then Maybe.andThen (Just << perform ChatBox.SetGame << succeed)
                <| Maybe.andThen .currentGame new.group
            else Nothing
            
        ]

getChanges_Config : GameViewInfo -> GameViewInfo -> Cmd GameViewMsg
getChanges_Config old new =
    if (old.chats /= new.chats) || (old.user /= new.user) ||
        (old.group /= new.group)
    then Task.perform PushConfig <| Task.succeed ()
    else Cmd.none

getChanges_Voting : GameViewInfo -> GameViewInfo -> Cmd GameViewMsg
getChanges_Voting old new =
    Cmd.batch <| List.map (Cmd.map WrapVoting) <| List.filterMap identity
        [ if old.chats /= new.chats
            then Just <| perform Voting.SetRooms <| Task.succeed new.chats
            else Nothing
        , if old.votes /= new.votes
            then Just <| perform SetVotes <| Task.succeed new.votes
            else Nothing
        , if old.user /= new.user
            then Just <| perform Voting.SetUser <| Task.succeed new.user
            else Nothing
        , if old.group /= new.group
            then Just <| perform Voting.SetLeader <| Task.succeed <|
                case new.group of
                    Nothing -> False
                    Just group -> group.leader == new.ownUserId
            else Nothing
        , if old.group /= new.group
            then Just <| perform Voting.SetGame <| Task.succeed <|
                Maybe.map .id <| Maybe.andThen .currentGame <|
                new.group
            else Nothing
        ]

getChanges_NewGame : GameViewInfo -> GameViewInfo -> Cmd GameViewMsg
getChanges_NewGame old new =
    Cmd.batch <| List.filterMap identity
        [ if new.newGame == Nothing
            then case new.group of
                Nothing -> Nothing
                Just group -> case group.currentGame of
                    Just _ -> Nothing
                    Nothing -> Just <| Task.perform (always CreateNewGame) <| 
                        Task.succeed ()
            else Nothing
        , if new.installedTypes /= old.installedTypes
            then case new.installedTypes of
                Just it -> Just <| Cmd.batch <| (::)
                    ( Task.perform 
                        (WrapNewGame << NewGame.SetInstalledTypes) <|
                        Task.succeed it
                    ) <| List.singleton <| Task.perform SendNetwork <|
                    Task.succeed <| RespMulti <| Multi <| 
                    ( List.map (RespInfo << Request.CreateOptions) <|
                        Maybe.withDefault [] new.installedTypes
                    ) ++
                    (List.map (RespInfo << Rolesets) <|
                        Maybe.withDefault [] new.installedTypes
                    )
                Nothing -> Nothing
            else Nothing
        , if new.createOptions /= old.createOptions
            then Just <| Task.perform WrapNewGame <| Task.succeed <|
                NewGame.SetCreateOptions new.createOptions
            else Nothing
        , if (new.newGame /= Nothing) && (new.user /= old.user)
            then Just <| Task.perform WrapNewGame <| Task.succeed <|
                NewGame.SetUser <| List.filter (\u -> u.user /= new.ownUserId ) <|
                new.user
            else Nothing
        , if (new.newGame /= Nothing) && (new.rolesets /= old.rolesets)
            then Just <| Task.perform WrapNewGame <| Task.succeed <|
                NewGame.SetRoleset new.rolesets
            else Nothing
        ]

(./=) : (a -> b) -> a -> a -> Bool
(./=) f a b = (f a) /= (f b)

replace : (a -> Bool) -> a -> List a -> List a
replace check new list = (::) new <| List.filter check list

find : (a -> Bool) -> List a -> Maybe a
find f list =
    case list of
        [] -> Nothing
        l :: ls ->
            if f l
            then Just l
            else find f ls

requestUpdatedGroup : Group -> Request
requestUpdatedGroup group =
    let
        groupMaxTime = Maybe.withDefault 0 <| List.maximum <| List.filterMap identity
            [ Just group.created
            , group.lastTime
            , Maybe.map .started group.currentGame
            , Maybe.andThen .finished group.currentGame
            ]
        phaseDay = Maybe.map 
            (\g -> (g.phase, g.day)) 
            group.currentGame
    in
        RespConv <| GetUpdatedGroup <| GroupVersion
            group.id 
            groupMaxTime 
            group.leader
            phaseDay

requestChangedVotings : Group -> Int -> Maybe Request
requestChangedVotings group lastChange =
    Maybe.andThen
        (Just << RespConv << flip GetChangedVotings lastChange)
        <| Maybe.map
            .id
            group.currentGame

requestChangedVotings2 : Game -> Int -> Request
requestChangedVotings2 game lastChange =
    RespConv <| GetChangedVotings game.id lastChange

getNewestVotingTime : Chat -> Int
getNewestVotingTime chat = Maybe.withDefault 0 <| List.maximum <| 
    List.filterMap identity <| List.concat <| List.map
        (\voting ->
            [ Just voting.created
            , voting.voteStart
            , voting.voteEnd
            ]
        )
        chat.voting

requestChatEntrys : ChatId -> Int -> Request
requestChatEntrys chatId lastChange =
    RespConv <| GetNewChatEntrys chatId (lastChange - 1)

requestNewVotes : Chat -> Int -> List Request
requestNewVotes chat lastChange = List.map
    (flip requestNewVotesS lastChange) chat.voting

requestNewVotesS : Game.Types.Types.Voting -> Int -> Request
requestNewVotesS voting lastChange =
    RespConv <| GetNewVotes voting.chat voting.voteKey (lastChange - 1)

getViewType : GameViewInfo -> GameViewViewType
getViewType info =
    case info.group of
        Nothing -> ViewLoading
        Just group -> case group.currentGame of
            Nothing ->
                if group.leader == info.ownUserId 
                then case info.newGame of
                    Just _ -> ViewInitGame
                    Nothing -> ViewLoading
                else ViewWaitGame
            Just game -> case game.finished of
                Just _ -> case info.newGame of
                    Just _ -> ViewInitGame
                    Nothing -> ViewFinished
                Nothing ->
                    if info.hasPlayer
                    then ViewNormalGame
                    else ViewGuest

modifyVotes : Dict VoteKey (Dict UserId Vote) -> Chat -> Dict VoteKey (Dict UserId Vote)
modifyVotes dict chat =
    let
        ck : List String
        ck = List.map .voteKey chat.voting
        dk : List String
        dk = Dict.keys dict
        remove : List String
        remove = List.filter (not << flip List.member ck) <| dk
        add : List String
        add = List.filter (not << flip List.member dk) <| ck
        d1 : Dict VoteKey (Dict UserId Vote)
        d1 = List.foldr Dict.remove dict remove
        d2 : Dict VoteKey (Dict UserId Vote)
        d2 = List.foldr (flip Dict.insert Dict.empty) d1 add
    in d2

view : GameView -> Html GameViewMsg
view (GameView info) = case getViewType info of
    ViewLoading -> loading
    ViewInitGame -> div [ class "w-box-game-view", attribute "data-view" <| toString <| getViewType info ] 
        [ div 
            [ class <| (++) "w-box-panel w-box-player " <| 
                if info.showPlayers then "visible" else ""
            ]
            [ Html.map WrapUserListBox <| 
                UserListBox.view info.userListBox 
            ]
        , case info.newGame of
            Just newGame -> Html.map WrapNewGame <| MC.view newGame
            Nothing -> div [] []
        ]
    ViewWaitGame -> div [ class "w-box-game-view", attribute "data-view" <| toString <| getViewType info ] 
        [ div 
            [ class <| (++) "w-box-panel w-box-player " <| 
                if info.showPlayers then "visible" else ""
            ]
            [ Html.map WrapUserListBox <| 
                UserListBox.view info.userListBox 
            ]
        , WaitGameCreation.view info.config
        ]
    ViewNormalGame -> div [ class "w-box-game-view", attribute "data-view" <| toString <| getViewType info ] 
        [ div 
            [ class <| (++) "w-box-panel w-box-player" <| 
                if info.showPlayers then " visible" else ""
            ]
            [ Html.map WrapUserListBox <| 
                UserListBox.view info.userListBox 
            ]
        , Html.map WrapChatBox <| MC.view <| case info.chatBox of
            Just cb -> cb
            Nothing -> Debug.crash "GameView:view:ViewNormalGame - chatBox should exists"
        ,div 
            [ class <| (++) "w-box-panel w-box-voting" <| 
                if info.showVotes then " visible" else ""
            ]
            [ Html.map WrapVoting <| MC.view <| case info.voting of
                Just v -> v
                Nothing -> Debug.crash "GameView:view:ViewNormalGame - voting should exists"
            ]
        --, Html.text <| toString info
        ]
    ViewGuest -> div [ class "w-box-game-view", attribute "data-view" <| toString <| getViewType info ] 
        [ div 
            [ class <| (++) "w-box-panel w-box-player " <| 
                if info.showPlayers then "visible" else ""
            ]
            [ Html.map WrapUserListBox <| 
                UserListBox.view info.userListBox 
            ]
        , Html.map WrapChatBox <| MC.view <| case info.chatBox of
            Just cb -> cb
            Nothing -> Debug.crash "GameView:view:ViewGuest - chatBox should exists"
        ]
    ViewFinished -> div [ class "w-box-game-view", attribute "data-view" <| toString <| getViewType info ] 
        [ div 
            [ class <| (++) "w-box-panel w-box-player " <| 
                if info.showPlayers then "visible" else ""
            ]
            [ Html.map WrapUserListBox <| 
                UserListBox.view info.userListBox 
            ]
        , GameFinished.view info.config
            (maybeCrash <| Maybe.map ((==) info.ownUserId << .leader) info.group)
            (maybeCrash <| Maybe.andThen .currentGame <| info.group)
            CreateNewGame
        ]

maybeCrash : Maybe a -> a
maybeCrash v = case v of
    Just v -> v
    Nothing -> Debug.crash "var shouldn't be Nothing. Report this error on https://github.com/Garados007/Werwolf"

subscriptions : GameView -> Sub GameViewMsg
subscriptions (GameView info) =
    Sub.map WrapUserListBox <| UserListBox.subscriptions info.userListBox