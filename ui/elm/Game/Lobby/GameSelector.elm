module Game.Lobby.GameSelector exposing
    ( GameSelector
    , GameSelectorMsg
        ( SetConfig
        , SetGames
        , SetCurrent
        )
    , GameSelectorEvent (..)
    , GameSelectorDef
    , gameSelectorModule
    )

import ModuleConfig as MC exposing (..)

import Game.Configuration exposing (..)
import Game.Utils.Language exposing (..)
import Config exposing (..)

import Html exposing (Html,div,text)
import Html.Attributes exposing (class,attribute)
import Html.Events exposing (onClick)
import Dict exposing (Dict)

type GameSelector = GameSelector GameSelectorInfo

type alias GameSelectorInfo =
    { config : LangConfiguration
    , games : Dict Int String
    , current : Maybe Int
    }

type GameSelectorMsg
    -- public methods
    = SetConfig LangConfiguration
    | SetGames (Dict Int String)
    | SetCurrent (Maybe Int)
    -- private methods
    | OnChangeCurrent Int

type GameSelectorEvent
    = ChangeCurrent (Maybe Int)

type alias GameSelectorDef a = ModuleConfig GameSelector GameSelectorMsg
    () GameSelectorEvent a

gameSelectorModule : (GameSelectorEvent -> List a) ->
    (GameSelectorDef a, Cmd GameSelectorMsg, List a)
gameSelectorModule event = createModule
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }
    event ()

init : () -> (GameSelector, Cmd GameSelectorMsg, List a)
init () =
    ( GameSelector
        { config = LangConfiguration empty <|
            createLocal (newGlobal lang_backup) Nothing
        , games = Dict.empty
        , current = Nothing
        }
    , Cmd.none
    , []
    )

update : GameSelectorDef a -> GameSelectorMsg -> GameSelector -> (GameSelector, Cmd GameSelectorMsg, List a)
update def msg (GameSelector model) = case msg of
    SetConfig config ->
        ( GameSelector { model | config = config }
        , Cmd.none
        , []
        )
    SetGames games ->
        ( GameSelector { model | games = games }
        , Cmd.none
        , []
        )
    SetCurrent current ->
        ( GameSelector { model | current = current }
        , Cmd.none
        , []
        )
    OnChangeCurrent id ->
        ( GameSelector { model | current = Just id }
        , Cmd.none
        , MC.event def <| ChangeCurrent <| Just id
        )

view : GameSelector -> Html GameSelectorMsg
view (GameSelector model) = div [ class "w-gameselector-box" ] 
    [ div [ class "w-game-selector-tabarea" ]
        <| viewButtons model
    ]

viewButtons : GameSelectorInfo -> List (Html GameSelectorMsg)
viewButtons model = 
    List.map (\(id, name) ->
        div [ class <| (++) "w-gameselector-button" <|
                if Just id == model.current
                then " selected"
                else ""
            , onClick (OnChangeCurrent id)
            ]
            [ div [] [ text name ] ]
    ) <| Dict.toList model.games

subscriptions : GameSelector -> Sub GameSelectorMsg
subscriptions (GameSelector model) =
    Sub.none