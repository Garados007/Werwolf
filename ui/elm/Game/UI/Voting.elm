module Game.UI.Voting exposing 
    ( Voting
    , VotingMsg
    , VotingEvent (..)
    , init
    , view
    , update 
    )

import Html exposing (Html,div,text,ul,li)
import Html.Attributes exposing (class,style)
import Html.Events exposing (onClick)
import List
import Dict exposing (Dict)
import Char
import Task
import Time exposing (Posix)

import Game.Utils.Dates exposing (DateTimeFormat (..), convert)
import Game.Types.Request as Request exposing 
    (Request(..), RequestControl(..))
import Game.Types.Types as Types exposing (..)
import Game.Configuration exposing (..)
import Game.Utils.Language exposing (..)
import Game.Data as Data exposing (Data)
import UnionDict exposing (UnionDict, SafeDict)

type alias TVoting = Types.Voting

type Voting = Voting VotingInfo

type alias VotingInfo =
    { groupId : GroupId
    , info : SafeDict (Int, String) (ChatId, VoteKey) Bool
    }

type VotingMsg
    -- public methods
    -- private methods
    = OnVote ChatId VoteKey PlayerId
    | OnVoteStart ChatId VoteKey
    | OnVoteEnd ChatId VoteKey
    | OnNextRound GameId
    | OnChangeVis ChatId VoteKey
    | OnCloseBox

type VotingEvent 
    = Send Request
    | CloseBox

init : GroupId -> Voting
init group = Voting
    { groupId = group
    , info = UnionDict.include Dict.empty
    }

view : Data -> LangLocal -> Voting -> Html VotingMsg
view data lang (Voting model) = div [ class "w-voting-box" ] 
    <| (::) (viewBoxHeader lang model) 
    <| (::) (viewGameControl data lang model) 
    <| List.map (viewVoting data lang model) 
    <| List.concat 
    <| List.map (.chat >> .voting) 
    <| UnionDict.values
    <| UnionDict.unsafen ChatId Types.chatId 
    <| Maybe.withDefault (UnionDict.include Dict.empty)
    <| Maybe.map .chats 
    <| UnionDict.get model.groupId
    <| UnionDict.unsafen GroupId Types.groupId
    <| data.game.groups

viewVoting : Data -> LangLocal -> VotingInfo -> TVoting -> Html VotingMsg
viewVoting data lang info voting = div [ class "w-voting" ] 
    [ div 
        [ class "w-voting-header" 
        , onClick (OnChangeVis voting.chat voting.voteKey)
        ]
        [ text <| getSingle lang [ "ui", "voting" ]
        , text " - "
        , div [ class "w-voting-chat" ]
            [ text <| chatName data lang info voting.chat ]
        , text " - "
        , div [ class "w-voting-room" ]
            [ text <| voteName data lang info voting.chat voting.voteKey ]
        ]
    , div 
        [ class "w-voting-sub-header" 
        , onClick (OnChangeVis voting.chat voting.voteKey)
        ]
        [ text <| getSingle lang [ "ui", "created" ]
        , text ": "
        , div [ class "w-voting-created" ]
            [ text <| dateName data lang info <| Just voting.created ]
        , text " - "
        , text <| getSingle lang [ "ui", "started"  ]
        , text ": "
        , div [ class "w-voting-started" ]
            [ text <| dateName data lang info voting.voteStart ]
        , text " - "
        , text <| getSingle lang [ "ui", "voteEnd" ]
        , text ": "
        , div [ class "w-voting-ended" ]
            [ text <| dateName data lang info voting.voteEnd ]
        ]
    , div 
        [ class "w-voting-votes" 
        , onClick (OnChangeVis voting.chat voting.voteKey)
        ]
        [ div [ class "w-voting-bar-container" ]
            [ div [ class "w-voting-bar" ]
                [ div 
                    [ class "w-voting-bar-fill"
                    , style "width" 
                        <| ( String.fromFloat
                            <| 100 * (toFloat <| voteCount data info voting) /
                            (toFloat <| List.length voting.enabledUser)
                            ) 
                        ++ "%"
                    ] []
                ]
            ]
        , div [ class "w-voting-info-container" ]
            [ text <| String.fromInt <| voteCount data info voting
            , text "/"
            , text <| String.fromInt <| List.length voting.enabledUser
            ]
        ]
    , let vis = info.info
                |> UnionDict.unsafen
                    (Tuple.mapBoth ChatId VoteKey)
                    (Tuple.mapBoth Types.chatId Types.voteKey)
                |> UnionDict.get (voting.chat, voting.voteKey)
                |> Maybe.withDefault False
        in if vis
            then viewSingleVotingInfo data lang info voting
            else if canShowVoteSelection data info voting
            then viewVoteSelection data info voting
            else div [] []
    , if isLeader data info
        then viewVoteControl lang info voting
        else div [] []
    ]

isLeader : Data -> VotingInfo -> Bool 
isLeader data info = data.game.groups
    |> UnionDict.unsafen GroupId Types.groupId 
    |> UnionDict.get info.groupId
    |> Maybe.map (.group >> .leader)
    |> Maybe.map ((==) data.game.ownId << Just)
    |> Maybe.withDefault False

canShowVoteSelection : Data -> VotingInfo -> TVoting -> Bool
canShowVoteSelection data info voting =
    (voting.voteStart /= Nothing) 
    && (voting.voteEnd == Nothing) 
    &&  ( data.game.ownId
            |> Maybe.map (\id -> hasUser data info id voting.enabledUser)
            |> Maybe.withDefault False
        )

viewVoteSelection : Data -> VotingInfo -> TVoting -> Html VotingMsg
viewVoteSelection data info voting = 
    div [ class "w-voting-voting" ] <| List.map
        (\user ->
            div [ class "w-voting-select-user"
                , onClick <| OnVote voting.chat 
                    voting.voteKey user
                ]
                [ text <| userName data info user ]
        )
        voting.targetUser

viewVoteControl : LangLocal -> VotingInfo -> TVoting -> Html VotingMsg
viewVoteControl lang info voting =
    div [ class "w-voting-control" ] <| List.filterMap identity <|
        [ if voting.voteStart == Nothing
            then Just <| div 
                [ class "w-voting-start" 
                , onClick <| OnVoteStart voting.chat voting.voteKey
                ]
                [ text <| getSingle lang 
                    ["ui", "start-voting"] 
                ]
            else Nothing
        , if (voting.voteStart /= Nothing) && (voting.voteEnd == Nothing)
            then Just <| div 
                [ class "w-voting-end" 
                , onClick <| OnVoteEnd voting.chat voting.voteKey
                ]
                [ text <| getSingle lang 
                    ["ui", "end-voting"] 
                ]
            else Nothing
        ]

viewGameControl : Data -> LangLocal -> VotingInfo -> Html VotingMsg
viewGameControl data lang info =
    if (&&) (isLeader data info)
        <| (/=) Nothing
        <| Maybe.map .id
        <| Maybe.andThen (.currentGame << .group)
        <| UnionDict.get info.groupId
        <| UnionDict.unsafen GroupId Types.groupId 
        <| data.game.groups
    then 
        div [ class "w-voting-game-control" ] <| 
            [ div [ class "w-voting-game-control-title" ]
                [ text <| getSingle lang
                    [ "ui", "game-control"]
                ]
            , div
                [ class "w-voting-next-round"
                , onClick 
                    <| OnNextRound
                    <| Maybe.withDefault (GameId 0)
                    <| Maybe.map .id 
                    <| Maybe.andThen (.currentGame << .group)
                    <| UnionDict.get info.groupId
                    <| UnionDict.unsafen GroupId Types.groupId 
                    <| data.game.groups
                ]
                [ text <| getSingle lang
                    [ "ui", "next-round" ]
                ]
            ]
    else div [] []

viewBoxHeader : LangLocal -> VotingInfo -> Html VotingMsg
viewBoxHeader lang info = div [ class "w-box-header"]
    [ div [ class "w-box-header-title" ]
        [ text <| getSingle lang
            [ "ui", "vote-header" ]
        ]
    , div [ class "w-box-header-close", onClick OnCloseBox ]
        [ text "X" ]
    ]

viewSingleVotingInfo : Data -> LangLocal -> VotingInfo -> TVoting -> Html VotingMsg
viewSingleVotingInfo data lang info voting =
    let votes : UnionDict Int PlayerId Vote
        votes = data.game.groups 
            |> UnionDict.unsafen GroupId Types.groupId 
            |> UnionDict.get info.groupId
            |> Maybe.map .chats 
            |> Maybe.withDefault (UnionDict.include Dict.empty)
            |> UnionDict.unsafen ChatId Types.chatId 
            |> UnionDict.get voting.chat 
            |> Maybe.map .votes 
            |> Maybe.withDefault (UnionDict.include Dict.empty)
            |> UnionDict.unsafen VoteKey Types.voteKey 
            |> UnionDict.get voting.voteKey 
            |> Maybe.withDefault (UnionDict.include Dict.empty)
            |> UnionDict.unsafen PlayerId Types.playerId
        missing : List PlayerId
        missing = List.filter
            (\key -> not 
                <| List.member key
                <| List.map .voter
                <| UnionDict.values votes
            )
            voting.enabledUser
    in div [ class "w-voting-info-box" ]
        [ div [ class "w-voting-info-header" ]
            [ text <| getSingle lang ["ui", "voting-votes"] ]
        , if UnionDict.size votes == 0
            then div [ class "w-voting-info-none" ]
                [ text <| getSingle lang ["ui", "noone-voted"] ]
            else div [ class "w-voting-info-votes" ] <| List.map
                (\vote -> div [ class "w-voting-info-vote-single" ]
                    [ div [] [ text <| userName data info vote.voter ]
                    , div [] [ text <| String.fromChar <| Char.fromCode 8594 ]
                    , div [] [ text <| userName data info vote.target ]
                    ]
                )
                <| UnionDict.values votes
        , div [ class "w-voting-info-header" ]
            [ text <| getSingle lang [ "ui", "voting-waits" ] ]
        , if List.length missing == 0
            then div [ class "w-voting-info-none" ]
                [ text <| getSingle lang ["ui", "noone-missing"] ]
            else ul [ class "w-voting-info-missing" ] <| List.map
                ( li [ class "w-voting-info-missing-single" ]
                    << List.singleton << text << userName data info
                )
                <| missing
        , div [ class "w-voting-info-header" ]
            [ text <| getSingle lang [ "ui", "voting-targets"] ]
        , if List.length voting.targetUser == 0
            then div [ class "w-voting-info-none" ]
                [ text <| getSingle lang [ "ui", "no-targets" ] ]
            else ul [ class "w-voting-info-targets" ] <| List.map
                ( li [ class "w-voting-info-target-single" ]
                    << List.singleton << text << userName data info
                )
                voting.targetUser
        ]

hasUser : Data -> VotingInfo -> UserId -> List PlayerId -> Bool
hasUser data info id list =
    case data.game.groups 
        |> UnionDict.unsafen GroupId Types.groupId 
        |> UnionDict.get info.groupId
        |> Maybe.map .user 
        |> Maybe.withDefault []
        |> List.filter ((==) id << .user)
    of
        [] -> False
        u :: us -> case u.player of
            Nothing -> False
            Just player -> List.member player.id list

userName : Data -> VotingInfo -> PlayerId -> String
userName data info id =
    let
        func : User -> Bool
        func = \user -> case user.player of
            Nothing -> False
            Just player -> player.id == id
    in  case data.game.groups 
            |> UnionDict.unsafen GroupId Types.groupId 
            |> UnionDict.get info.groupId
            |> Maybe.map .user 
            |> Maybe.withDefault []
            |> find func
        of
            Nothing -> (++) "Player #" 
                <| String.fromInt
                <| Types.playerId id
            Just user -> user.stats.name

chatName : Data -> LangLocal -> VotingInfo -> ChatId -> String
chatName data lang info id =
    case data.game.groups 
        |> UnionDict.unsafen GroupId Types.groupId 
        |> UnionDict.get info.groupId
        |> Maybe.map .chats 
        |> Maybe.withDefault (UnionDict.include Dict.empty)
        |> UnionDict.unsafen ChatId Types.chatId 
        |> UnionDict.get id
    of
        Just chat -> getChatName lang chat.chat.chatRoom
        Nothing -> (++) "Chat #" 
            <| String.fromInt
            <| Types.chatId id

voteName : Data -> LangLocal -> VotingInfo -> ChatId -> VoteKey -> String
voteName data lang info id key =
    case data.game.groups 
        |> UnionDict.unsafen GroupId Types.groupId 
        |> UnionDict.get info.groupId
        |> Maybe.map .chats 
        |> Maybe.withDefault (UnionDict.include Dict.empty)
        |> UnionDict.unsafen ChatId Types.chatId 
        |> UnionDict.get id
    of
        Just chat -> getVotingName lang chat.chat.chatRoom 
            <| Types.voteKey key
        Nothing -> "[" ++ (Types.voteKey key) ++ "]"

dateName : Data -> LangLocal -> VotingInfo -> Maybe Posix -> String
dateName data lang info time = case time of
    Nothing -> getSingle lang [ "ui", "not-yet" ]
    Just t -> convert data.config.votingDateFormat 
        t
        data.time.zone

voteCount : Data -> VotingInfo -> TVoting -> Int
voteCount data info voting = data.game.groups
    |> UnionDict.unsafen GroupId Types.groupId 
    |> UnionDict.get info.groupId
    |> Maybe.map .chats 
    |> Maybe.withDefault (UnionDict.include Dict.empty)
    |> UnionDict.unsafen ChatId Types.chatId 
    |> UnionDict.get voting.chat
    |> Maybe.map .votes 
    |> Maybe.withDefault (UnionDict.include Dict.empty)
    |> UnionDict.unsafen VoteKey Types.voteKey 
    |> UnionDict.get voting.voteKey 
    |> Maybe.withDefault (UnionDict.include Dict.empty)
    |> UnionDict.extract 
    |> Dict.size

update : VotingMsg -> Voting -> (Voting, Cmd VotingMsg, List VotingEvent)
update msg (Voting info) = case msg of
    OnVote chatId voteKey playerId ->
        (Voting info
        , Cmd.none
        , List.singleton <| Send <| ReqControl <| Request.Vote
            chatId voteKey playerId
        )
    OnVoteStart chatId votekey ->
        ( Voting info
        , Cmd.none
        , List.singleton <| Send <| ReqControl <| Request.StartVoting
            chatId votekey
        )
    OnVoteEnd chatId votekey ->
        ( Voting info
        , Cmd.none
        , List.singleton <| Send <| ReqControl <| Request.FinishVoting
            chatId votekey
        )
    OnNextRound gameId->
        ( Voting info
        , Cmd.none
        , List.singleton 
            <| Send 
            <| ReqControl 
            <| Request.NextPhase gameId
        )
    OnChangeVis chat key ->
        let vis = not 
                <| Maybe.withDefault False 
                <| UnionDict.get (chat,key) 
                <| UnionDict.unsafen
                    (Tuple.mapBoth ChatId VoteKey)
                    (Tuple.mapBoth Types.chatId Types.voteKey)
                <| info.info
        in  ( Voting 
                { info 
                | info = info.info 
                    |> UnionDict.unsafen
                        (Tuple.mapBoth ChatId VoteKey)
                        (Tuple.mapBoth Types.chatId Types.voteKey)
                    |> UnionDict.insert (chat, key) vis 
                    |> UnionDict.safen
                }
            , Cmd.none
            , []
            )
    OnCloseBox ->
        ( Voting info
        , Cmd.none
        , [ CloseBox ]
        )

find : (a -> Bool) -> List a -> Maybe a
find func list = case list of
    [] -> Nothing
    l :: ls ->
        if func l
        then Just l
        else find func ls
