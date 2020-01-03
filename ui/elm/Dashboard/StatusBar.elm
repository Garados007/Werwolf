module Dashboard.StatusBar exposing (..)

import Dashboard.Environment exposing (..)
import Dashboard.Util.Html exposing (..)
import Html exposing (Html,div,text)
import Html.Attributes as HA exposing (class)
import Html.Events as HE
import Set exposing (Set)
import Dict
import Browser
import Config exposing (uri_host,uri_path)
import List

main : Platform.Program () StatusBar StatusBarMsg
main = Browser.element
    { init = \() -> (init, Cmd.none)
    , view = \model -> div []
        [ view model
        , dashboardStylesheet "status-bar"
        ]
    , update = \msg model ->
        update msg model 
        |> \(a, b, e) -> 
            let d_ = 
                    if List.isEmpty e
                    then e 
                    else Debug.log "event" e                
            in (a, b)
    , subscriptions = \_ -> Sub.none
    }

type alias StatusBar =
    {

    }

type StatusBarMsg 
    = NoOp

type StatusBarEvent
    = NoEvent

init : StatusBar 
init = {}

view : StatusBar -> Html StatusBarMsg
view bar = div [ class "status-bar" ]
    []

update : StatusBarMsg -> StatusBar 
    -> (StatusBar, Cmd StatusBarMsg, List StatusBarEvent)
update msg bar = case msg of 
    NoOp -> (bar, Cmd.none, [])

tripel : a -> b -> c -> (a, b, c)
tripel a b c = (a, b, c)
