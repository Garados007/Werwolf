module Game.UI.ChatInsertBox exposing
    ( Model
    , Msg (UpdateConfig)
    , EventMsg (..)
    , ChatInsertBoxDef
    , chatInsertBoxModule
    )

import ModuleConfig exposing (..)

import Html exposing (Html,program,div,textarea,text,button)
import Html.Attributes exposing (class,value)
import Html.Events exposing (onInput,onClick)

import Game.Utils.Keys exposing (onKeyUp,onKeyDown,keyEnter)
import Game.Utils.Keys.ModDetector exposing (ModDetector,newModDetector,setDown,setUp,isCtrl,isPressed)
import Game.Configuration exposing (..)
import Game.Utils.Language exposing (..)

type alias ChatInsertBoxDef a = ModuleConfig Model Msg LangConfiguration EventMsg a

chatInsertBoxModule : (EventMsg -> List a) -> LangConfiguration -> (ChatInsertBoxDef a, Cmd Msg, List a)
chatInsertBoxModule = createModule
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }

type alias Model =
    { config : LangConfiguration
    , text : String
    , modDetector : ModDetector
    }

type Msg    
    = ChangeText String
    | KeyDown Int
    | KeyUp Int
    | Send
    | UpdateConfig LangConfiguration

type EventMsg
    = SendEvent String

init : LangConfiguration -> (Model, Cmd Msg, List a)
init config = (Model config "" newModDetector, Cmd.none, [])

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
            [ text model.text
            ]
        , div [ class "chat-insert-box-button", onClick Send ]
            [ text <| getSingle model.config.lang ["ui", "send"]

            ]
        ]

update : ChatInsertBoxDef a -> Msg -> Model -> (Model, Cmd Msg, List a)
update def msg model =
    case msg of
        ChangeText text -> ({ model | text = text }, Cmd.none, [])
        Send ->
            ( { model | text = "" }
            , Cmd.none
            , event def <| SendEvent model.text
            )
        KeyDown key -> 
            let
                md = setDown model.modDetector key
                isSend = (isCtrl md) && (isPressed md keyEnter)
                events =
                    if isSend
                    then event def (SendEvent model.text)
                    else []
            in  ({ model 
                | modDetector = md
                , text = if isSend then "" else model.text 
                }
                , Cmd.none, events)
        KeyUp key -> ({ model | modDetector = setUp model.modDetector key }, Cmd.none, [])
        UpdateConfig config -> ({ model | config = config}, Cmd.none, [])

subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none