module Game.UI.Voting exposing 
    ( Voting
    , VotingMsg
        ( SetRooms
        , SetVotes
        , SetUser
        , SetConfig
        , SetLeader
        , SetGame
        )
    , VotingEvent (..)
    , VotingDef
    , votingModule
    )

import ModuleConfig as MC exposing (..)

import Html exposing (Html,div,text,ul,li)
import Html.Attributes exposing (class,style)
import Html.Events exposing (onClick)
import List
import Dict exposing (Dict)
import Char

import Game.Utils.Dates exposing (DateTimeFormat (..), convert)
import Game.Types.Request as Request exposing 
    (ChatId, UserId, VoteKey, PlayerId
    , Response(RespControl), ResponseControl(Vote))
import Game.Types.Types as Types exposing (..)
import Game.Utils.Network exposing (Request)
import Game.Configuration exposing (..)
import Game.Utils.Language exposing (..)

type alias TVoting = Types.Voting

type Voting = Voting VotingInfo

type alias VotingInfo =
    { config : LangConfiguration
    , ownId : Int
    , gameId : Maybe Int
    , room : Dict ChatId Chat
    , votes : Dict ChatId (Dict VoteKey (Dict UserId Vote))
    , user : List User
    , isLeader : Bool
    , info : Dict (ChatId, VoteKey) Bool
    }

type VotingMsg
    -- public methods
    = SetRooms (Dict ChatId Chat)
    | SetVotes (Dict ChatId (Dict VoteKey (Dict UserId Vote)))
    | SetUser (List User)
    | SetConfig LangConfiguration
    | SetLeader Bool
    | SetGame (Maybe Int)
    -- private methods
    | OnVote ChatId VoteKey PlayerId
    | OnVoteStart ChatId VoteKey
    | OnVoteEnd ChatId VoteKey
    | OnNextRound
    | OnChangeVis ChatId VoteKey
    | OnCloseBox

type VotingEvent 
    = Send Request
    | CloseBox

type alias VotingDef a = ModuleConfig Voting VotingMsg 
    (LangConfiguration, Int) VotingEvent a

votingModule : (VotingEvent -> List a) -> 
    (LangConfiguration, Int) -> 
    (VotingDef a, Cmd VotingMsg, List a)
votingModule = createModule
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    } 
    
init : (LangConfiguration, Int) -> (Voting, Cmd VotingMsg, List a)
init (config, ownId) =
    ( Voting <| VotingInfo config ownId Nothing
        Dict.empty Dict.empty [] False Dict.empty
    , Cmd.none
    , []
    )

single : VotingInfo -> List String -> String
single info = getSingle info.config.lang

view : Voting -> Html VotingMsg
view (Voting model) = div [ class "w-voting-box" ] <|
    (::) (viewBoxHeader model) <|
    (::) (viewGameControl model) <|
    List.map (viewVoting model) <|
    List.concat <|
    List.map .voting <|
    Dict.values model.room

viewVoting : VotingInfo -> TVoting -> Html VotingMsg
viewVoting info voting = div [ class "w-voting" ] 
    [ div 
        [ class "w-voting-header" 
        , onClick (OnChangeVis voting.chat voting.voteKey)
        ]
        [ text <| single info [ "ui", "voting" ]
        , text " - "
        , div [ class "w-voting-chat" ]
            [ text <| chatName info voting.chat ]
        , text " - "
        , div [ class "w-voting-room" ]
            [ text <| voteName info voting.chat voting.voteKey ]
        ]
    , div 
        [ class "w-voting-sub-header" 
        , onClick (OnChangeVis voting.chat voting.voteKey)
        ]
        [ text <| single info [ "ui", "created" ]
        , text ": "
        , div [ class "w-voting-created" ]
            [ text <| dateName info <| Just voting.created ]
        , text " - "
        , text <| single info [ "ui", "started"  ]
        , text ": "
        , div [ class "w-voting-started" ]
            [ text <| dateName info voting.voteStart ]
        , text " - "
        , text <| single info [ "ui", "voteEnd" ]
        , text ": "
        , div [ class "w-voting-ended" ]
            [ text <| dateName info voting.voteEnd ]
        ]
    , div 
        [ class "w-voting-votes" 
        , onClick (OnChangeVis voting.chat voting.voteKey)
        ]
        [ div [ class "w-voting-bar-container" ]
            [ div [ class "w-voting-bar" ]
                [ div 
                    [ class "w-voting-bar-fill"
                    , style 
                        [ ("width", (toString <| 
                            100 * (toFloat <| voteCount info voting) /
                            (toFloat <| List.length voting.enabledUser)) ++
                            "%" )
                        ]
                    ] []
                ]
            ]
        , div [ class "w-voting-info-container" ]
            [ text <| toString <| voteCount info voting
            , text "/"
            , text <| toString <| List.length voting.enabledUser
            ]
        ]
    , let vis = Dict.get (voting.chat, voting.voteKey) info.info
                |> Maybe.withDefault False
        in if vis
            then viewSingleVotingInfo info voting
            else if canShowVoteSelection info voting
            then viewVoteSelection info voting
            else div [] []
    , if info.isLeader
        then viewVoteControl info voting
        else div [] []
    ]

canShowVoteSelection : VotingInfo -> TVoting -> Bool
canShowVoteSelection info voting =
    (voting.voteStart /= Nothing) &&
    (voting.voteEnd == Nothing) &&
    (hasUser info info.ownId voting.enabledUser)

viewVoteSelection : VotingInfo -> TVoting -> Html VotingMsg
viewVoteSelection info voting = 
    div [ class "w-voting-voting" ] <| List.map
        (\user ->
            div [ class "w-voting-select-user"
                , onClick <| OnVote voting.chat 
                    voting.voteKey user
                ]
                [ text <| userName info user ]
        )
        voting.targetUser

viewVoteControl : VotingInfo -> TVoting -> Html VotingMsg
viewVoteControl info voting =
    div [ class "w-voting-control" ] <| List.filterMap identity <|
        [ if voting.voteStart == Nothing
            then Just <| div 
                [ class "w-voting-start" 
                , onClick <| OnVoteStart voting.chat voting.voteKey
                ]
                [ text <| getSingle info.config.lang 
                    ["ui", "start-voting"] 
                ]
            else Nothing
        , if (voting.voteStart /= Nothing) && (voting.voteEnd == Nothing)
            then Just <| div 
                [ class "w-voting-end" 
                , onClick <| OnVoteEnd voting.chat voting.voteKey
                ]
                [ text <| getSingle info.config.lang 
                    ["ui", "end-voting"] 
                ]
            else Nothing
        ]

viewGameControl : VotingInfo -> Html VotingMsg
viewGameControl info =
    if info.isLeader && (info.gameId /= Nothing)
    then 
        div [ class "w-voting-game-control" ] <| 
            [ div [ class "w-voting-game-control-title" ]
                [ text <| getSingle info.config.lang
                    [ "ui", "game-control"]
                ]
            , div
                [ class "w-voting-next-round"
                , onClick <| OnNextRound
                ]
                [ text <| getSingle info.config.lang
                    [ "ui", "next-round" ]
                ]
            ]
    else div [] []

viewBoxHeader : VotingInfo -> Html VotingMsg
viewBoxHeader info = div [ class "w-box-header"]
    [ div [ class "w-box-header-title" ]
        [ text <| getSingle info.config.lang
            [ "ui", "vote-header" ]
        ]
    , div [ class "w-box-header-close", onClick OnCloseBox ]
        [ text "X" ]
    ]

viewSingleVotingInfo : VotingInfo -> TVoting -> Html VotingMsg
viewSingleVotingInfo info voting =
    let votes = Dict.get voting.chat info.votes
            |> Maybe.andThen (Dict.get voting.voteKey)
            |> Maybe.withDefault Dict.empty
        missing = List.filter
            (not << flip List.member (Dict.values votes |> List.map .voter))
            voting.enabledUser
    in div [ class "w-voting-info-box" ]
        [ div [ class "w-voting-info-header" ]
            [ text <| getSingle info.config.lang ["ui", "voting-votes"] ]
        , if Dict.size votes == 0
            then div [ class "w-voting-info-none" ]
                [ text <| getSingle info.config.lang ["ui", "noone-voted"] ]
            else div [ class "w-voting-info-votes" ] <| List.map
                (\vote -> div [ class "w-voting-info-vote-single" ]
                    [ div [] [ text <| userName info vote.voter ]
                    , div [] [ text <| String.fromChar <| Char.fromCode 8594 ]
                    , div [] [ text <| userName info vote.target ]
                    ]
                )
                <| Dict.values votes
        , div [ class "w-voting-info-header" ]
            [ text <| getSingle info.config.lang [ "ui", "voting-waits" ] ]
        , if List.length missing == 0
            then div [ class "w-voting-info-none" ]
                [ text <| getSingle info.config.lang ["ui", "noone-missing"] ]
            else ul [ class "w-voting-info-missing" ] <| List.map
                ( li [ class "w-voting-info-missing-single" ]
                    << List.singleton << text << userName info
                )
                <| missing
        , div [ class "w-voting-info-header" ]
            [ text <| getSingle info.config.lang [ "ui", "voting-targets"] ]
        , if List.length voting.targetUser == 0
            then div [ class "w-voting-info-none" ]
                [ text <| getSingle info.config.lang [ "ui", "no-targets" ] ]
            else ul [ class "w-voting-info-targets" ] <| List.map
                ( li [ class "w-voting-info-target-single" ]
                    << List.singleton << text << userName info
                )
                voting.targetUser
        ]

hasUser : VotingInfo -> UserId -> List PlayerId -> Bool
hasUser info id list =
    case List.filter ((==) id << .user) info.user of
        [] -> False
        u :: us -> case u.player of
            Nothing -> False
            Just player -> List.member player.id list

userName : VotingInfo -> UserId -> String
userName info id =
    let
        func : User -> Bool
        func = \user -> case user.player of
            Nothing -> False
            Just player -> player.id == id
    in case find func info.user of
        Nothing -> (++) "User #" <| toString id
        Just user -> user.stats.name

chatName : VotingInfo -> ChatId -> String
chatName info id =
    case Dict.get id info.room of
        Just chat -> getChatName info.config.lang chat.chatRoom
        Nothing -> "Chat #" ++ (toString id)

voteName : VotingInfo -> ChatId -> String -> String
voteName info id key =
    case Dict.get id info.room of
        Just chat -> getVotingName info.config.lang chat.chatRoom key
        Nothing -> "[" ++ key ++ "]"

dateName : VotingInfo -> Maybe Int -> String
dateName info time = case time of
    Nothing -> single info [ "ui", "not-yet" ]
    Just t -> convert info.config.conf.votingDateFormat (toFloat t * 1000)

voteCount : VotingInfo -> TVoting -> Int
voteCount info voting = case Dict.get voting.chat info.votes of
    Nothing -> 0
    Just c -> case Dict.get voting.voteKey c of
        Nothing -> 0
        Just d -> Dict.size d

update : VotingDef a -> VotingMsg -> Voting -> (Voting, Cmd VotingMsg, List a)
update def msg (Voting info) = case msg of
    SetRooms room -> 
        let minfo = Dict.toList room
                |> List.map 
                    (\(rid,r) -> 
                        List.map
                            (\v -> ((rid, v.voteKey), False))
                            r.voting
                    )
                |> List.concat
                |> Dict.fromList
            ninfo = Dict.merge
                (\(id,key) vis result -> Dict.insert (id,key) vis result)
                (\(id,key) vis1 vis2 result -> Dict.insert (id,key) vis2 result)
                (\(id,key) vis result -> result)
                minfo
                info.info
                Dict.empty
        in (Voting { info | room = room, info = ninfo }, Cmd.none, [])
    SetVotes votes -> (Voting { info | votes = votes }, Cmd.none, [])
    SetUser user -> (Voting { info | user = user }, Cmd.none, [])
    SetConfig config -> (Voting { info | config = config }, Cmd.none, [])
    SetLeader leader -> (Voting { info | isLeader = leader }, Cmd.none, [])
    SetGame game -> (Voting { info | gameId = game}, Cmd.none, [])
    OnVote chatId voteKey playerId ->
        (Voting info
        , Cmd.none
        , MC.event def <| Send <| RespControl <| Request.Vote
            chatId voteKey playerId
        )
    OnVoteStart chatId votekey ->
        ( Voting info
        , Cmd.none
        , MC.event def <| Send <| RespControl <| Request.StartVoting
            chatId votekey
        )
    OnVoteEnd chatId votekey ->
        ( Voting info
        , Cmd.none
        , MC.event def <| Send <| RespControl <| Request.FinishVoting
            chatId votekey
        )
    OnNextRound ->
        ( Voting info
        , Cmd.none
        , MC.event def <| Send <| RespControl <| Request.NextPhase
            <| Maybe.withDefault 0 info.gameId
        )
    OnChangeVis chat key ->
        let vis = not <| Maybe.withDefault False <| Dict.get (chat,key) info.info
        in ( Voting { info | info = Dict.insert (chat, key) vis info.info }, Cmd.none, [])
    OnCloseBox ->
        ( Voting info
        , Cmd.none
        , MC.event def <| CloseBox
        )

subscriptions : Voting -> Sub VotingMsg
subscriptions model = Sub.none

find : (a -> Bool) -> List a -> Maybe a
find func list = case list of
    [] -> Nothing
    l :: ls ->
        if func l
        then Just l
        else find func ls
