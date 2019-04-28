module Game.Lobby.GameSelector exposing
    ( GameSelector
    , GameSelectorMsg
    , GameSelectorEvent (..)
    , msgSetCurrent
    , init 
    , view
    , update
    )

import Game.Configuration exposing (..)
import Game.Utils.Language exposing (..)
import Config exposing (..)
import Game.Data as Data exposing (..)
import Game.Types.Types as Types exposing (..)
import DataDiff.Path as Diff exposing (DetectorPath, Path (..))
import DataDiff.Ex exposing (SingleActionEx (..), ModActionEx (..))
import UnionDict exposing (UnionDict)

import Html exposing (Html,div,text)
import Html.Attributes exposing (class,attribute)
import Html.Events exposing (onClick)
import Dict exposing (Dict)

type GameSelector = GameSelector GameSelectorInfo

type alias GameSelectorInfo =
    { current : Maybe GroupId
    }

type GameSelectorMsg
    -- public methods
    = SetCurrent (Maybe GroupId)
    -- private methods
    | OnChangeCurrent GroupId
    | OnOpenMenu

msgSetCurrent : Maybe GroupId -> GameSelectorMsg
msgSetCurrent = SetCurrent

type GameSelectorEvent
    = ChangeCurrent GroupId
    | OpenMenu

init : GameSelector
init = GameSelector
    { current = Nothing
    }

update : GameSelectorMsg -> GameSelector -> (GameSelector, Cmd GameSelectorMsg, List GameSelectorEvent)
update msg (GameSelector model) = case msg of
    SetCurrent current ->
        ( GameSelector { model | current = current }
        , Cmd.none
        , []
        )
    OnChangeCurrent id ->
        ( GameSelector { model | current = Just id }
        , Cmd.none
        , [ ChangeCurrent id ]
        )
    OnOpenMenu ->
        ( GameSelector model
        , Cmd.none
        , [ OpenMenu ]
        )

view : Data -> GameSelector -> Html GameSelectorMsg
view data (GameSelector model) = div [ class "w-gameselector-box" ] 
    [ div [ class "w-gameselector-nav", onClick OnOpenMenu ] <|
        List.repeat 3 <| div [] []
    , div [ class "w-gameselector-tabs" ]
        [ div [ class "w-game-selector-tabarea" ]
            <| viewButtons data model
        ]
    ]

viewButtons : Data -> GameSelectorInfo -> List (Html GameSelectorMsg)
viewButtons data model = List.map 
    (\(id, name) ->
        div [ class <| (++) "w-gameselector-button" <|
                if Just id == model.current
                then " selected"
                else ""
            , onClick (OnChangeCurrent id)
            ]
            [ div [] [ text name ] ]
    )
    <| UnionDict.toList 
    <| UnionDict.map (\_ -> .group >> .name)
    <| UnionDict.unsafen GroupId Types.groupId
    <| data.game.groups