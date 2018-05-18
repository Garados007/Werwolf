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
    )

import Game.Types.Types exposing (..)
import Game.Types.Changes exposing (..)
import Game.Types.CreateOptions exposing (..)
import Game.Utils.Network exposing (Request)
import Game.Types.Request exposing (..)

import Html exposing (Html,div)
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
    , chats : List Chat
    , user : List User
    , periods : List Request
    , entrys : Dict ChatId (Dict Int ChatEntry)
    , votes : Dict ChatId (Dict VoteKey (Dict UserId Vote))
    , installedTypes : List String
    , createOptions : Dict String CreateOptions
    , rolesets : Dict String (List String)
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

type alias ChangeVar a =
    { new : a
    , register : List Request
    , unregister : List Request
    , send : List Request
    }

combine : ChangeVar a -> ChangeVar a -> ChangeVar a
combine a b = ChangeVar b.new 
    (a.register ++ b.register) 
    (a.unregister ++ b.unregister)
    (a.send ++ b.send)

init : Int -> Int -> (GameView, Cmd GameViewMsg)
init groupId ownUserId =
    ( GameView
        { group = Nothing
        , hasPlayer = False
        , ownUserId = ownUserId
        , lastVotingChange = 0
        , lastChatTime = 0
        , lastVoteTime = 0
        , chats = []
        , user = []
        , periods = []
        , entrys = Dict.empty
        , votes = Dict.empty
        , installedTypes = []
        , createOptions = Dict.empty
        , rolesets = Dict.empty
        }
    , perform SendNetwork <| succeed <| initRequest groupId ownUserId
    )

initRequest : Int -> Int -> Request
initRequest groupId ownUserId =
    RespMulti <| Multi 
        [ RespGet <| GetGroup groupId
        , RespGet <| GetUserFromGroup groupId
        ]

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
        in (GameView nm, Cmd.batch cmd)
    Disposing ->
        (GameView model
        , Cmd.batch <| List.map (Task.perform UnregisterNetwork << Task.succeed) model.periods
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
                        , chats = []
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
                old = find (\c-> c.id == chat.id) info.chats
                time = max info.lastVotingChange <| 
                    getNewestVotingTime chat
                dict : Dict VoteKey (Dict UserId Vote)
                dict = case Dict.get chat.id info.votes of
                    Just d -> modifyVotes d chat
                    Nothing -> modifyVotes Dict.empty chat
            in ChangeVar
                { info
                | chats = (::) chat <| List.filter ((./=) .id chat) info.chats
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
            case find (\c -> c.id == voting.chat) info.chats of
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
                        | chats = replace (\c -> c.id == nc.id) nc info.chats
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
                , chats = []
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

requestNewVotesS : Voting -> Int -> Request
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
view (GameView info) = div [] 
    [ Html.text <| toString info ]
