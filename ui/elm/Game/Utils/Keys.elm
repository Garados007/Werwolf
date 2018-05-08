module Game.Utils.Keys exposing (..)

import Json.Decode as Json
import Html exposing (Attribute)
import Html.Events exposing (keyCode, on)

onKeyUp : (Int -> msg) -> Attribute msg
onKeyUp tagger =
    on "keyup" (Json.map tagger keyCode)

onKeyDown : (Int -> msg) -> Attribute msg
onKeyDown tagger =
    on "keydown" (Json.map tagger keyCode)

keyShift : Int
keyShift = 16
keyCtrl : Int
keyCtrl = 17
keyAlt : Int
keyAlt = 18
keyEnter : Int
keyEnter = 13

onEnter : msg -> Attribute msg
onEnter msg =
    let
        isEnter code =
            if code == keyEnter
            then Json.succeed msg
            else Json.fail "not Enter"
    in
        on "keydown" (Json.andThen isEnter keyCode)
        