module Game.UI.GameView exposing
    ( GameView
    , GameViewMsg
        ( RegisterNetwork
        , UnregisterNetwork
        , SendNetwork
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
import Game.Types.CreateOptions exposing (..)
import Game.Utils.Network exposing (Request)
import Game.Types.Request exposing (..)
import Game.UI.UserListBox as UserListBox exposing (UserListBox, UserListBoxMsg (..))
import Game.UI.ChatBox as ChatBox exposing 
    (ChatBox, ChatBoxMsg (..), ChatBoxDef, ChatBoxEvent, chatBoxModule)
import Game.UI.Voting as Voting exposing (..)
import Game.UI.Loading as Loading exposing (loading)

import Html exposing (Html,div,text)
import Html.Attributes exposing (class)
import Task exposing (succeed, perform)
import Dict exposing (Dict)

type GameView = GameView GameViewInfo

type alias GameViewInfo =
    { group : Maybe Group
    , hasPlayer : Bool
    , ownUserId : Int
    , lastVotingChange : Int
    , lastChatTime : Int
    , lastVoteTime : Int
    , chats : Dict ChatId Chat
    , user : List User
    , periods : List Request
    , entrys : Dict ChatId (Dict Int ChatEntry)
    , votes : Dict ChatId (Dict VoteKey (Dict UserId Vote))
    , installedTypes : List String
    , createOptions : Dict String CreateOptions
    , rolesets : Dict String (List String)
    , userListBox : UserListBox
    , chatBox : ChatBoxDef Int EventMsg
    , voting : VotingDef EventMsg
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
    -- public methods
    | Manage (List Changes)
    | Disposing --unregisters all registered requests and other cleanup
    -- Wrapper methods
    | WrapUserListBox UserListBoxMsg
    | WrapChatBox ChatBoxMsg
    | WrapVoting VotingMsg

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

combine : ChangeVar a -> ChangeVar a -> ChangeVar a
combine a b = ChangeVar b.new 
    (a.register ++ b.register) 
    (a.unregister ++ b.unregister)
    (a.send ++ b.send)

init : Int -> Int -> (GameView, Cmd GameViewMsg)
init groupId ownUserId =
    let 
        own = perform SendNetwork <| succeed <| initRequest groupId ownUserId
        (userListBox, ulbCmd) = UserListBox.init
        (chatBox, cbCmd, cbTasks) = chatBoxModule handleChatBox groupId
        (voting, vCmd, vTasks) = votingModule handleVoting ownUserId
        info = 
            { group = Nothing
            , hasPlayer = False
            , ownUserId = ownUserId
            , lastVotingChange = 0
            , lastChatTime = 0
            , lastVoteTime = 0
            , chats = Dict.empty
            , user = []
            , periods = []
            , entrys = Dict.empty
            , votes = Dict.empty
            , installedTypes = []
            , createOptions = Dict.empty
            , rolesets = Dict.empty
            , userListBox = userListBox
            , chatBox = chatBox
            , voting = voting
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
    )

update : GameViewMsg -> GameView -> (GameView, Cmd GameViewMsg)
update msg (GameView model) = case msg of
    Manage changes ->
        let
            changed = performUpdate updateGroup model changes
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
            nm = { new | periods = req1 }
            cmd_ulb = getChanges_UserListBox model nm
            cmd_cb = getChanges_ChatBox model nm
            cmd_v = getChanges_Voting model nm
        in (GameView nm, Cmd.batch (cmd ++ [cmd_ulb, cmd_cb, cmd_v]))
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
    WrapChatBox wmsg -> 
        let (nm, wcmd, wtasks) = MC.update model.chatBox wmsg
            (tm, tcmd) = handleEvent { model | chatBox = nm } wtasks
        in  ( GameView tm
            , Cmd.batch <| (Cmd.map WrapChatBox wcmd) :: tcmd
            )
    WrapVoting wmsg ->
        let (nm, wcmd, wtasks) = MC.update model.voting wmsg
            (tm, tcmd) = handleEvent { model | voting = nm } wtasks
        in  ( GameView tm
            , Cmd.batch <| (Cmd.map WrapVoting wcmd) :: tcmd
            )
    _ -> (GameView model, Cmd.none)

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

updateGroup : GameViewInfo -> Changes -> ChangeVar GameViewInfo
updateGroup info change = 
    case change of
        CGroup group ->
            case info.group of
                Nothing -> ChangeVar
                    { info | group = Just group }
                    (List.filterMap identity
                        [ Just <| requestUpdatedGroup group
                        , requestChangedVotings group info.lastVotingChange
                        , Just <| RespConv <| LastOnline group.id
                        ]
                    )
                    []
                    (List.filterMap identity 
                        [ Maybe.map
                            (\game -> RespGet <| GetChatRooms game.id)
                            group.currentGame
                        ]
                    )
                Just old -> ChangeVar
                    ( if group.currentGame == Nothing
                    then { info
                        | group = Just group
                        , chats = Dict.empty
                        , entrys = Dict.empty
                        , votes = Dict.empty
                        }
                    else { info | group = Just group }
                    )
                    (List.filterMap identity 
                        [ Just <| requestUpdatedGroup group
                        , requestChangedVotings group info.lastVotingChange
                        ]
                    )
                    (List.filterMap identity 
                        [ Just <| requestUpdatedGroup old
                        , requestChangedVotings old info.lastVotingChange
                        ]
                    )
                    (List.filterMap identity 
                        [ if old /= group
                            then Maybe.map
                                (\game -> RespGet <| GetChatRooms game.id)
                                group.currentGame
                            else Nothing
                        ]
                    )
        CUser user -> ChangeVar
            { info
            | user = (::) user <| List.filter ((./=) .user user) info.user
            , hasPlayer =
                if user.user == info.ownUserId
                then user.player /= Nothing
                else info.hasPlayer
            }
            [] [] []
        CLastOnline list -> ChangeVar
            { info
            | user = List.map
                (\user -> pushUpdate
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
                )
                info.user
            } [] [] []
        CChat chat -> 
            let 
                old = Dict.get chat.id info.chats
                time = max info.lastVotingChange <| 
                    getNewestVotingTime chat
                dict : Dict VoteKey (Dict UserId Vote)
                dict = case Dict.get chat.id info.votes of
                    Just d -> modifyVotes d chat
                    Nothing -> modifyVotes Dict.empty chat
            in ChangeVar
                { info
                | chats = Dict.insert chat.id chat info.chats
                , lastVotingChange = time
                , entrys = Dict.insert chat.id Dict.empty info.entrys
                , votes = Dict.insert chat.id dict info.votes
                } 
                (List.append
                    [ requestChatEntrys chat.id info.lastChatTime ]
                    <| requestNewVotes chat info.lastVoteTime
                )
                ( List.append
                    ( Maybe.withDefault []
                        <| Maybe.map 
                            (List.singleton << 
                                flip requestChatEntrys info.lastChatTime
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
                    time = max info.lastChatTime entry.sendDate
                    nd = Dict.insert entry.id entry dict

                in ChangeVar
                    { info
                    | lastChatTime = time
                    , entrys = Dict.insert entry.chat nd info.entrys
                    }
                    [ requestChatEntrys entry.chat time
                    ] 
                    [ requestChatEntrys entry.chat info.lastChatTime
                    ] 
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
        CGame game -> ChangeVar
            ( if game.finished == Nothing
            then { info
                | group = Maybe.map (\g -> { g | currentGame = Just game }) info.group
                , chats = Dict.empty
                , entrys = Dict.empty
                , votes = Dict.empty
                }
            else { info | group = Maybe.map (\g -> { g | currentGame = Just game }) info.group }
            )
            [ requestChangedVotings2 game info.lastVotingChange
            ]
            (case Maybe.andThen .currentGame info.group of
                Nothing -> []
                Just old -> 
                    [ requestChangedVotings2 old info.lastVotingChange
                    ]
            )
            (if Maybe.withDefault False <| 
                Maybe.map ((/=) game ) <| 
                Maybe.andThen .currentGame info.group
                then [ RespGet <| GetChatRooms game.id ]
                else []
            )
        CInstalledGameTypes list -> ChangeVar
            { info | installedTypes = list } [] [] []
        CCreateOptions key options -> ChangeVar
            { info | createOptions = Dict.insert key options info.createOptions } [] [] []
        CRolesets key list -> ChangeVar
            { info | rolesets = Dict.insert key list info.rolesets } [] [] []
        _ -> ChangeVar info [] [] []

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
                List.filter (\ce -> ce.sendDate > old.lastChatTime) <|
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
        ]

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
                then ViewInitGame
                else ViewWaitGame
            Just game -> case game.finished of
                Just _ -> ViewFinished
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
    ViewInitGame -> div [] 
        [ div 
            [ class <| (++) "w-box-panel w-box-player " <| 
                if info.showPlayers then "visible" else ""
            ]
            [ Html.map WrapUserListBox <| 
                UserListBox.view info.userListBox 
            ]
        ]
    ViewWaitGame -> div [] 
        [ div 
            [ class <| (++) "w-box-panel w-box-player " <| 
                if info.showPlayers then "visible" else ""
            ]
            [ Html.map WrapUserListBox <| 
                UserListBox.view info.userListBox 
            ]
        , text "wait a moment"
        ]
    ViewNormalGame -> div [] 
        [ div 
            [ class <| (++) "w-box-panel w-box-player" <| 
                if info.showPlayers then " visible" else ""
            ]
            [ Html.map WrapUserListBox <| 
                UserListBox.view info.userListBox 
            ]
        , Html.map WrapChatBox <| MC.view info.chatBox
        ,div 
            [ class <| (++) "w-box-panel w-box-voting" <| 
                if info.showVotes then " visible" else ""
            ]
            [ Html.map WrapVoting <| MC.view info.voting
            ]
        , Html.text <| toString info
        ]
    ViewGuest -> div [] 
        [ div 
            [ class <| (++) "w-box-panel w-box-player " <| 
                if info.showPlayers then "visible" else ""
            ]
            [ Html.map WrapUserListBox <| 
                UserListBox.view info.userListBox 
            ]
        , Html.map WrapChatBox <| MC.view info.chatBox
        , text "finished"
        ]
    ViewFinished -> div [] 
        [ div 
            [ class <| (++) "w-box-panel w-box-player " <| 
                if info.showPlayers then "visible" else ""
            ]
            [ Html.map WrapUserListBox <| 
                UserListBox.view info.userListBox 
            ]
        , text "finished"
        ]

subscriptions : GameView -> Sub GameViewMsg
subscriptions (GameView info) =
    Sub.map WrapUserListBox <| UserListBox.subscriptions info.userListBox