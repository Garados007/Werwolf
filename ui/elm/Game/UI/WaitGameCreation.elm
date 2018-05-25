module Game.UI.WaitGameCreation exposing (..)

import Html exposing (Html,div,text)
import Html.Attributes exposing (class)
import Game.Configuration exposing (..)
import Game.Utils.Language exposing (..)

view : LangConfiguration -> Html msg
view config =
    div [ class "w-wait-creation"]
        [ div [ class "w-wait-box"]
            [ div [ class "w-wait-text" ]
                [ text <| getSingle config.lang
                    ["ui","wait-for-admin"]
                ]
            ]
        ]