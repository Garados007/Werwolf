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
gs model key = getSingle model.config.lang [ "lobby", "option", key ]

view : Options -> Html OptionsMsg
view (Options model) = 
    let configChanger : (a -> Configuration -> Configuration) -> a -> OptionsMsg
        configChanger mod var =
            OnConfigChange <| \m -> { m | conf = mod var m.conf }
        conf = model.config.conf
    in modal OnClose (getSingle model.config.lang ["lobby", "options"]) <|
        div [ class "w-options-box" ] 
            [ div [ class "w-options-header" ]
                [ text <| gs model "datetime" ]
            , div [] [ text <| gs model "chatDateFormat" ]
            , viewDateInput 
                (configChanger <| \tf c -> { c | chatDateFormat = tf } )
                conf.chatDateFormat
            , div [] [ text <| gs model "profileTimeFormat" ]
            , viewDateInput 
                (configChanger <| \tf c -> { c | profileTimeFormat = tf } )
                conf.profileTimeFormat
            , div [] [ text <| gs model "profileDateFormat" ]
            , viewDateInput 
                (configChanger <| \tf c -> { c | profileDateFormat = tf } )
                conf.profileDateFormat
            , div [] [ text <| gs model "votingDateFormat" ]
            , viewDateInput 
                (configChanger <| \tf c -> { c | votingDateFormat = tf } )
                conf.votingDateFormat
            , div [] [ text <| gs model "manageGroupsDateFormat" ]
            , viewDateInput
                (configChanger <| \tf c -> { c | manageGroupsDateFormat = tf } )
                conf.manageGroupsDateFormat
            , div [ class "w-options-header" ]
                [ text <| gs model "style" ]
            , div [] [ text <| gs model "theme" ]
            , viewListInput
                (configChanger <| \tf c -> { c | theme = tf } )
                conf.theme
                themes
            , div
                [ class "w-options-reset"
                , onClick <| configChanger reset ()
                ]
                [ text <| gs model "reset" ]
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

viewListInput : (String -> OptionsMsg) -> String -> List String -> Html OptionsMsg
viewListInput msg current list = node "select"
    [ on "change" <| Json.map msg Html.Events.targetValue
    ] <| List.map
        (\entry -> node "option"
            [ value entry
            , selected <| entry == current
            ]
            [ text entry ]
        )
        list

example : DateTimeFormat -> String
example = flip convert 1514761199000.0

reset : () -> Configuration -> Configuration
reset _ conf = { empty | language = conf.language }

subscriptions : Options -> Sub OptionsMsg
subscriptions (Options model) =
    Sub.none