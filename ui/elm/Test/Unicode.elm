module Test.Unicode exposing (..)

import Html exposing (..)
import String
import Char
import List

table = node "table"
tr = node "tr"
th = node "th"

main = table [] <|
    tr []
        [ td [] [ text "number"]
        , td [] [ text "unicode" ]
        ]
    :: 
    (List.map 
        (\num -> tr []
            [ td [] [ text <| toString num ]
            , td [] [ text <| flip String.cons "" <| Char.fromCode num ]
            ]
        )
        <| List.range 0 1000
    )