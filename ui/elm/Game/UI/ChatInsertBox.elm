module Game.UI.ChatInsertBox exposing
    ( Model
    , Msg
    , EventMsg (..)
    , init 
    , view
    , update
    )

import Html exposing (Html,div,textarea,text,button)
import Html.Attributes exposing (class,value)
import Html.Events exposing (onInput,onClick)

import Game.Utils.Keys exposing (onKeyUp,onKeyDown,keyEnter)
import Game.Utils.Keys.ModDetector exposing (ModDetector,newModDetector,setDown,setUp,isCtrl,isPressed)
import Game.Utils.Language exposing (..)



type Model = Model
    { text : String
    , modDetector : ModDetector
    }

type Msg    
    = ChangeText String
    | KeyDown Int
    | KeyUp Int
    | Send

type EventMsg
    = SendEvent String

init : (Model, Cmd Msg)
init = 
    (Model 
        { text = ""
        , modDetector = newModDetector
        }
    , Cmd.none
    )

view : LangLocal -> Model -> Html Msg
view lang (Model model) = 
    div [ class "chat-insert-box" ]
        [ textarea 
            [ class "chat-insert-box-textarea"
            , onInput ChangeText 
            , onKeyDown KeyDown
            , onKeyUp KeyUp
            , value model.text
            ]
            [ text model.text
            ]
        , div [ class "chat-insert-box-button", onClick Send ]
            [ text <| getSingle lang ["ui", "send"] ]
        ]

update : Msg -> Model -> (Model, Cmd Msg, List EventMsg)
update msg (Model model) =
    case msg of
        ChangeText text -> (Model { model | text = text }, Cmd.none, [])
        Send ->
            ( Model { model | text = "" }
            , Cmd.none
            , [ SendEvent model.text ]
            )
        KeyDown key -> 
            let
                md = setDown model.modDetector key
                isSend = (isCtrl md) && (isPressed md keyEnter)
                events =
                    if isSend
                    then [ SendEvent model.text ]
                    else []
            in  ( Model { model 
                | modDetector = md
                , text = if isSend then "" else model.text 
                }
                , Cmd.none, events)
        KeyUp key ->  
            ( Model { model | modDetector = setUp model.modDetector key }
            , Cmd.none
            , []
            )
