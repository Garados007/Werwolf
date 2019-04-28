module Game.UI.WaitGameCreation exposing (..)

import Html exposing (Html,div,text)
import Html.Attributes exposing (class)
import Game.Utils.Language exposing (..)

view : LangLocal -> Html msg
view lang =
    div [ class "w-wait-creation"]
        [ div [ class "w-wait-box"]
            [ div [ class "w-wait-text" ]
                [ text <| getSingle lang
                    ["ui","wait-for-admin"]
                ]
            ]
        ]