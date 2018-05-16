module Test.TypesResponseHandling exposing (main)

import Html exposing (Html,program, div, input, pre, text, button)
import Html.Attributes exposing (type_, value, style)
import Html.Events exposing (onInput, onClick)

import Http
import HttpBuilder exposing (..)
import Config exposing (..)
import Time

import Game.Types.Response exposing (..)
import Game.Types.DecodeResponse exposing (..)
import Game.Types.Changes exposing (..)

type alias Model =
    { insertUrl : String
    , response : Maybe Response
    , error : String
    , changes : ChangeConfig
    }

type Msg 
    = Input String
    | Call
    | Fetch (Result.Result Http.Error Game.Types.Response.Response)

main : Program Never Model Msg
main = program 
    { init = (Model "" Nothing "" (ChangeConfig [] False), Cmd.none)
    , view = view
    , update = update
    , subscriptions = \_ -> Sub.none
    }

view : Model -> Html Msg
view model =
    div []
        [ input
            [ type_ "text"
            , value model.insertUrl
            , onInput Input
            , style 
                [ ("width", "95%")
                ]
            ] []
        , button
            [ onClick Call
            ]
            [ text "Send"
            ]
        , div []
            [ text model.error ]
        , if model.error /= "" then div [] []
        else div
            [ style
                [ ("margin", "1em 0")
                , ("font-family", "monospace")
                ]
            ]
            [ text (toString model.response)
            ]
        , if model.error /= "" then div [] [] 
        else div
            [ style
                [  ("margin", "1em 0")
                , ("font-family", "monospace")
                ]
            ]
            [ text (toString model.changes)
            ]
        ]

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        Input t -> ({ model | insertUrl = t}, Cmd.none)
        Call ->
            ({ model
                | error = ""
                , response = Nothing
                }   
            , HttpBuilder.post (uri_host ++ uri_path ++ model.insertUrl)
                |> withHeader "X-Test" "abc"
                |> withTimeout (10 * Time.second)
                |> withExpect (Http.expectJson decodeResponse)
                |> withCredentials
                |> send Fetch
            )
        Fetch res ->
            case res of
                Err err ->
                    ({ model
                        | error = toString err
                        , response = Nothing
                        }
                    , Cmd.none
                    )
                Ok resp ->
                    ({ model
                        | response = Just resp
                        , error = ""
                        , changes = concentrate resp
                        }
                    , Cmd.none   
                    )