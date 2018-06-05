module Game.Lobby.ModalWindow exposing (modal)

import Html exposing (Html,div,text)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)

divc : Html msg -> Html msg
divc = div [] << List.singleton

modal : msg -> String -> Html msg -> Html msg
modal close title content =
    div [ class "w-modal-outer" ]
        [ div [ class "w-modal-box" ]
            [ div [ class "w-modal-header" ] 
                [ div [ class "w-modal-title"]
                    [ text title ]
                , div [ class "w-modal-close", onClick close]
                    [ text "X" ]
                ]
            , div [ class "w-modal-content" ]
                [ content ]
            ]
        ]