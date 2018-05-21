module Test.TestGameView exposing (main)

import Game.UI.GameView as GameView exposing (..)
import Game.Utils.Network as Network exposing (..)

import Html exposing (program, Html, div)
import Html.Attributes exposing (style)
import Task exposing (succeed, perform)

type alias Model =
    { network : Network
    , gameView : GameView
    }

type Msg
    = MNetwork NetworkMsg
    | MGameView GameViewMsg

main : Program Never Model Msg
main = program 
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }

init : (Model, Cmd Msg)
init = 
    let 
        (gameView, gcmd) = GameView.init 3 1
    in (Model network gameView, Cmd.map MGameView gcmd)

view : Model -> Html Msg
view model = div [ style [("margin-bottom","50px")]] 
    [ Html.map MGameView <| GameView.view model.gameView ]

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        MNetwork nmsg ->
            case nmsg of
                Received changes ->
                    let
                        (nm, ncmd) = Network.update nmsg model.network
                        (ng, gcmd) = GameView.update (Manage changes.changes) model.gameView
                    in 
                        ( Model nm ng
                        , Cmd.batch
                            [ Cmd.map MNetwork ncmd
                            , Cmd.map MGameView gcmd
                            ]
                        )
                _ ->
                    let
                        (nm, cmd) = Network.update nmsg model.network
                    in ({ model | network = nm}, Cmd.map MNetwork cmd)
        MGameView gmsg ->
            case gmsg of
                RegisterNetwork req ->
                    let
                        nm = addRegulary model.network req
                        (ng, gcmd) = GameView.update gmsg model.gameView
                    in (Model nm ng, Cmd.map MGameView gcmd)
                UnregisterNetwork req ->
                    let
                        nm = addRegulary model.network req
                        (ng, gcmd) = GameView.update gmsg model.gameView
                    in (Model nm ng, Cmd.map MGameView gcmd) 
                SendNetwork req ->
                    let
                        ncmd = send model.network req
                        (ng, gcmd) = GameView.update gmsg model.gameView
                    in 
                        ( { model | gameView = ng }
                        , Cmd.batch
                            [ Cmd.map MNetwork ncmd
                            , Cmd.map MGameView gcmd
                            ]
                        )
                _ -> 
                    let
                        (ng, gcmd) = GameView.update gmsg model.gameView
                    in ({ model | gameView = ng }, Cmd.map MGameView gcmd) 

subscriptions : Model -> Sub Msg
subscriptions model = Sub.batch
    [ Sub.map MNetwork <| Network.subscriptions model.network 
    , Sub.map MGameView <| GameView.subscriptions model.gameView
    ]        