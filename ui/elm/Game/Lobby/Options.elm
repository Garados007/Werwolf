module Game.Lobby.Options exposing
    ( Options
    , OptionsMsg
        ( SetConfig
        )
    , OptionsEvent (..)
    , OptionsDef
    , optionsModule
    )
    
import ModuleConfig as MC exposing (..)

import Game.Configuration exposing (..)
import Game.Utils.Language exposing (..)
import Game.Utils.Dates exposing (DateTimeFormat(..),all,convert)
import Config exposing (..)
import Game.Lobby.ModalWindow exposing (modal)

import Html exposing (Html,div,text,a,img,input,node)
import Html.Attributes exposing (class,attribute,href,value,selected)
import Html.Events exposing (on,onClick)
import Dict exposing (Dict)
import Json.Decode as Json

type Options = Options OptionsInfo

type alias OptionsInfo =
    { config : LangConfiguration
    }

type OptionsMsg
    -- public Methods
    = SetConfig LangConfiguration
    -- private Methods
    | OnClose
    | OnConfigChange (LangConfiguration -> LangConfiguration)

type OptionsEvent
    = Close
    | UpdateConfig Configuration

type alias OptionsDef a = ModuleConfig Options OptionsMsg
    () OptionsEvent a

optionsModule : (OptionsEvent -> List a) ->
    (OptionsDef a, Cmd OptionsMsg, List a)
optionsModule event = createModule
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }
    event ()

init : () -> (Options, Cmd OptionsMsg, List a)
init () =
    ( Options
        { config = LangConfiguration empty <|
            createLocal (newGlobal lang_backup) Nothing
        }
    , Cmd.none
    , []
    )

update : OptionsDef a -> OptionsMsg -> Options -> (Options, Cmd OptionsMsg, List a)
update def msg (Options model) = case msg of
    SetConfig config ->
        ( Options { model | config = config }
        , Cmd.none
        , []
        )
    OnClose ->
        ( Options model
        , Cmd.none
        , event def Close
        )
    OnConfigChange mod ->
        let config = mod model.config
        in  if config /= model.config
            then
                ( Options { model | config = config }
                , Cmd.none
                , MC.event def <| UpdateConfig config.conf
                )
            else (Options model, Cmd.none, [])

gs : OptionsInfo -> String -> String
gs model key = getSingle model.config.lang [ "lobby", key ]

view : Options -> Html OptionsMsg
view (Options model) = 
    let configChanger : (a -> Configuration -> Configuration) -> a -> OptionsMsg
        configChanger mod var =
            OnConfigChange <| \m -> { m | conf = mod var m.conf }
        conf = model.config.conf
    in modal OnClose (gs model "options") <|
        div [ class "w-options-box" ] 
            [ div [ class "w-options-header" ]
                [ text <| gs model "opt-datetime" ]
            , div [] [ text <| gs model "opt-chatDateFormat" ]
            , viewDateInput 
                (configChanger <| \tf c -> { c | chatDateFormat = tf } )
                conf.chatDateFormat
            , div [] [ text <| gs model "opt-profileTimeFormat" ]
            , viewDateInput 
                (configChanger <| \tf c -> { c | profileTimeFormat = tf } )
                conf.profileTimeFormat
            , div [] [ text <| gs model "opt-profileDateFormat" ]
            , viewDateInput 
                (configChanger <| \tf c -> { c | profileDateFormat = tf } )
                conf.profileDateFormat
            , div [] [ text <| gs model "opt-votingDateFormat" ]
            , viewDateInput 
                (configChanger <| \tf c -> { c | votingDateFormat = tf } )
                conf.votingDateFormat
            , div
                [ class "w-options-reset"
                , onClick <| configChanger reset ()
                ]
                [ text <| gs model "opt-reset" ]
            ]

viewDateInput : (DateTimeFormat -> OptionsMsg) -> DateTimeFormat -> Html OptionsMsg
viewDateInput msg current = node "select"
    [ on "change" <| Json.map
        (msg << Maybe.withDefault current << flip Dict.get all)
        Html.Events.targetValue
    ] <| List.map
        (\(key,val) -> node "option"
            [ value key
            , selected <| val == current 
            ]
            [ text <| example val ]
        )
        <| Dict.toList all

example : DateTimeFormat -> String
example = flip convert 1514761199000.0

reset : () -> Configuration -> Configuration
reset _ conf = { empty | language = conf.language }

subscriptions : Options -> Sub OptionsMsg
subscriptions (Options model) =
    Sub.none