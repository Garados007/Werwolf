module Dashboard.Util.Html exposing (..)

import Html exposing (Html, div, text)
import Html.Attributes as HA exposing (class)
import Html.Events as HE
import Config exposing (uri_host,uri_path)
import Json.Decode as JD

stylesheet : String -> Html msg
stylesheet url = Html.node "link"
    [ HA.attribute "rel" "stylesheet"
    , HA.attribute "property" "stylesheet"
    , HA.attribute "href" url
    ] []

localStylesheet : String -> Html msg 
localStylesheet path = stylesheet
    <| uri_host
    ++ uri_path
    ++ path 

dashboardStylesheet : String -> Html msg 
dashboardStylesheet name = localStylesheet
    <| "ui/css/dashboard/"
    ++ name 
    ++ ".less"

onKeyEnter : msg -> Html.Attribute msg 
onKeyEnter tagger = HE.on "keyup"
    <| JD.andThen
        (\code ->
            if code == 13
            then JD.succeed tagger
            else JD.fail "wrong key code"
        )
    <| HE.keyCode