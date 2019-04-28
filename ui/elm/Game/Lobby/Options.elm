module Game.Lobby.Options exposing
    ( OptionsMsg
    , OptionsEvent (..)
    , detector
    , update
    , view
    )
    
import Game.Configuration exposing (..)
import Game.Utils.Language exposing (..)
import Game.Utils.Dates exposing (DateTimeFormat(..),all,convert)
import Config exposing (..)
import Game.Lobby.ModalWindow exposing (modal)
import Game.Data as Data exposing (..)
import DataDiff.Path as Diff exposing (DetectorPath, Path (..))
import DataDiff.Ex exposing (SingleActionEx (..), ModActionEx (..))
import UnionDict exposing (UnionDict)

import Html exposing (Html,div,text,a,img,input,node)
import Html.Attributes exposing (class,attribute,href,value,selected)
import Html.Events exposing (on,onClick)
import Dict exposing (Dict)
import Json.Decode as Json
import Time

type OptionsMsg
    -- public Methods
    -- private Methods
    = OnClose
    | OnConfigChange (Configuration -> Configuration)
    | ConfChanged Configuration

type OptionsEvent
    = Close
    | ModData (Data -> Data)
    | SaveConfig Configuration

detector : DetectorPath Data OptionsMsg 
detector = Diff.mapData .config
    <| Diff.value
        [ ChangedEx <| \_ _ -> ConfChanged 
        ]

update : OptionsMsg -> List OptionsEvent
update msg = case msg of
    OnClose -> [ Close ] 
    OnConfigChange mod ->
        [ ModData <| \data ->
            { data 
            | config = mod data.config 
            }
        ]
    ConfChanged conf -> [ SaveConfig conf ]

gs : LangLocal -> String -> String
gs lang key = getSingle lang [ "lobby", "option", key ]

view : Data -> LangLocal -> Html OptionsMsg
view data lang = 
    let configChanger : (a -> Configuration -> Configuration) -> a -> OptionsMsg
        configChanger mod var =
            OnConfigChange <| mod var
        conf = data.config
    in modal OnClose (getSingle lang ["lobby", "options"]) <|
        div [ class "w-options-box" ] 
            [ div [ class "w-options-header" ]
                [ text <| gs lang "datetime" ]
            , div [] [ text <| gs lang "chatDateFormat" ]
            , viewDateInput 
                (configChanger <| \tf c -> { c | chatDateFormat = tf } )
                conf.chatDateFormat
            , div [] [ text <| gs lang "profileTimeFormat" ]
            , viewDateInput 
                (configChanger <| \tf c -> { c | profileTimeFormat = tf } )
                conf.profileTimeFormat
            , div [] [ text <| gs lang "profileDateFormat" ]
            , viewDateInput 
                (configChanger <| \tf c -> { c | profileDateFormat = tf } )
                conf.profileDateFormat
            , div [] [ text <| gs lang "votingDateFormat" ]
            , viewDateInput 
                (configChanger <| \tf c -> { c | votingDateFormat = tf } )
                conf.votingDateFormat
            , div [] [ text <| gs lang "manageGroupsDateFormat" ]
            , viewDateInput
                (configChanger <| \tf c -> { c | manageGroupsDateFormat = tf } )
                conf.manageGroupsDateFormat
            , div [ class "w-options-header" ]
                [ text <| gs lang "style" ]
            , div [] [ text <| gs lang "theme" ]
            , viewListInput
                (configChanger <| \tf c -> { c | theme = tf } )
                conf.theme
                themes
            , div
                [ class "w-options-reset"
                , onClick <| configChanger always Game.Configuration.empty
                ]
                [ text <| gs lang "reset" ]
            ]

viewDateInput : (DateTimeFormat -> OptionsMsg) -> DateTimeFormat -> Html OptionsMsg
viewDateInput msg current = node "select"
    [ on "change" <| Json.map
        (\k -> msg <| Maybe.withDefault current <| Dict.get k all)
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
example format = convert format (Time.millisToPosix 1514761199000) Time.utc 
