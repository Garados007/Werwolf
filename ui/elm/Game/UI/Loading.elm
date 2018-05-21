module Game.UI.Loading exposing (..)

import Html exposing (Html,div)
import Html.Attributes exposing (class)

loading : Html msg
loading = div [ class "loading-box" ]
    []