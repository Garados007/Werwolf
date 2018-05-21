module Game.UI.Voting exposing 
    ( Voting
    , VotingMsg
        ( SetRooms
        , SetVotes
        , SetUser
        )
    , VotingEvent (..)
    , VotingDef
    , votingModule
    )

import ModuleConfig as MC exposing (..)

import Html exposing (Html,div,text)
import Html.Attributes exposing (class,style)
import Html.Events exposing (onClick)
import List
import Dict exposing (Dict)

import Game.Utils.Dates exposing (DateTimeFormat (..), convert)
import Game.Types.Request as Request exposing 
    (ChatId, UserId, VoteKey, PlayerId
    , Response(RespControl), ResponseControl(Vote))
import Game.Types.Types as Types exposing (..)
import Game.Utils.Network exposing (Request)

type alias TVoting = Types.Voting

type Voting = Voting VotingInfo

type alias VotingInfo =
    { ownId : Int
    , room : Dict ChatId Chat
    , votes : Dict ChatId (Dict VoteKey (Dict UserId Vote))
    , user : List User
    , dateFormat : DateTimeFormat
    }

type VotingMsg
    -- public methods
    = SetRooms (Dict ChatId Chat)
    | SetVotes (Dict ChatId (Dict VoteKey (Dict UserId Vote)))
    | SetUser (List User)
    | SetFormat DateTimeFormat
    -- private methods
    | OnVote ChatId VoteKey PlayerId

type VotingEvent 
    = Send Request

type alias VotingDef a = ModuleConfig Voting VotingMsg Int VotingEvent a

votingModule : (VotingEvent -> List a) -> Int -> (VotingDef a, Cmd VotingMsg, List a)
votingModule = createModule
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    } 
    
init : Int -> (Voting, Cmd VotingMsg, List a)
init ownId =
    ( Voting <| VotingInfo ownId Dict.empty Dict.empty [] DD_MM_YYYY_H24_M
    , Cmd.none
    , []
    )

view : Voting -> Html VotingMsg
view (Voting model) = div [ class "w-voting-box" ] <|
    List.map (viewVoting model) <|
    List.concat <|
    List.map .voting <|
    Dict.values model.room

viewVoting : VotingInfo -> TVoting -> Html VotingMsg
viewVoting info voting = div [ class "w-voting" ] 
    [ div [ class "w-voting-header" ]
        [ text "Voting - "
        , div [ class "w-voting-chat" ]
            [ text <| chatName info voting.chat ]
        , text " - "
        , div [ class "w-voting-room" ]
            [ text voting.voteKey ]
        ]
    , div [ class "w-voting-sub-header" ]
        [ text "created: "
        , div [ class "w-voting-created" ]
            [ text <| dateName info <| Just voting.created ]
        , text " - startet: "
        , div [ class "w-voting-started" ]
            [ text <| dateName info voting.voteStart ]
        , text " - voteEnd: "
        , div [ class "w-voting-ended" ]
            [ text <| dateName info voting.voteEnd ]
        ]
    , div [ class "w-voting-votes" ]
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
    , if canShowVoteSelection info voting
        then viewVoteSelection info voting
        else div [] []
    ]

canShowVoteSelection : VotingInfo -> TVoting -> Bool
canShowVoteSelection info voting =
    (voting.voteStart /= Nothing) &&
    (voting.voteEnd == Nothing) &&
    (hasUser info info.ownId voting.enabledUser)

viewVoteSelection : VotingInfo -> TVoting -> Html VotingMsg
viewVoteSelection info voting = 
    div [ class "w-voting-box" ] <| List.map
        (\user ->
            div [ class "w-voting-select-user"
                , onClick <| OnVote voting.chat 
                    voting.voteKey user
                ]
                [ text <| userName info user ]
        )
        voting.targetUser

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
        Just chat -> chat.chatRoom
        Nothing -> "Chat #" ++ (toString id)

dateName : VotingInfo -> Maybe Int -> String
dateName info time = case time of
    Nothing -> "not yet"
    Just t -> convert info.dateFormat (toFloat t * 1000)

voteCount : VotingInfo -> TVoting -> Int
voteCount info voting = case Dict.get voting.chat info.votes of
    Nothing -> 0
    Just c -> case Dict.get voting.voteKey c of
        Nothing -> 0
        Just d -> Dict.size d

update : VotingDef a -> VotingMsg -> Voting -> (Voting, Cmd VotingMsg, List a)
update def msg (Voting info) = case msg of
    SetRooms room -> (Voting { info | room = room }, Cmd.none, [])
    SetVotes votes -> (Voting { info | votes = votes }, Cmd.none, [])
    SetFormat format -> (Voting { info | dateFormat = format }, Cmd.none, [])
    SetUser user -> (Voting { info | user = user }, Cmd.none, [])
    OnVote chatId voteKey playerId ->
        (Voting info
        , Cmd.none
        , MC.event def <| Send <| RespControl <| Request.Vote
            chatId voteKey playerId
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