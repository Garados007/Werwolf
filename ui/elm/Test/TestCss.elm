module Test.TestCss exposing (main)

import Html exposing (Html,div,node)
import Html.Attributes exposing (attribute,class)

main : Html msg
main = div []
    [ node "link"
        [ attribute "rel" "stylesheet"
        , attribute "property" "stylesheet"
        , attribute "href" "test-css.css"
        ] []
    , div [ class "box" ] []
    ]