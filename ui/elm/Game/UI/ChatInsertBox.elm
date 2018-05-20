module Game.UI.ChatInsertBox exposing
    ( Model
    , Msg (Send)
    , init
    , view
    , update
    , subscriptions
    )

import Html exposing (Html,program,div,textarea,text,button)
import Html.Attributes exposing (class,value)
import Html.Events exposing (onInput,onClick)
import Html.Lazy exposing (lazy)

import Game.Utils.Keys exposing (onKeyUp,onKeyDown,keyEnter)
import Game.Utils.Keys.ModDetector exposing (ModDetector,newModDetector,setDown,setUp,isCtrl,isPressed)

import Task

main : Program Never Model Msg
main = program
    { init = init
    , view = lazy view
    , update = update
    , subscriptions = subscriptions
    }

type alias Model =
    { text : String
    , modDetector : ModDetector
    }

type Msg    
    = ChangeText String
    | KeyDown Int
    | KeyUp Int
    | Send String

init : (Model, Cmd Msg)
init = (Model "" newModDetector, Cmd.none)

view : Model -> Html Msg
view model = 
    div [ class "chat-insert-box" ]
        [ textarea 
            [ class "chat-insert-box-textarea"
            , onInput ChangeText 
            , onKeyDown KeyDown
            , onKeyUp KeyUp
            , value model.text
            ]
            [ --text model.text
            ]
        , button [ class "chat-insert-box-button", onClick (Send model.text) ]
            [ text "Send"

            ]
        ]

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        ChangeText text -> ({ model | text = text }, Cmd.none)
        Send text -> ({ model | text = "" }, Cmd.none)
        KeyDown key -> 
            let
                md = setDown model.modDetector key
                isSend = (isCtrl md) && (isPressed md keyEnter)
                task =
                    if isSend
                    then Task.perform Send (Task.succeed model.text)
                    else Cmd.none
            in
                ({ model | modDetector = md }, task)
        KeyUp key -> ({ model | modDetector = setUp model.modDetector key }, Cmd.none)

subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none