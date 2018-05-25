module Game.UI.GameFinished exposing (..)

import Html exposing (Html,div,text,ul,li)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)
import Game.Configuration exposing (..)
import Game.Utils.Language exposing (..)
import Game.Types.Types as Types exposing (..)

view : LangConfiguration -> Bool -> Game -> msg -> Html msg
view config isLeader game onNewGame =
    div [ class "w-finished"]
        [ div [ class "w-finished-box"]
            [ div [ class "w-finished-text" ]
                [ text <| getSingle config.lang
                    ["ui","game-finished"]
                ]
            , ul [] <| List.map (li [] << List.singleton << text) <|
                List.map (getSingle config.lang << (++) ["roles"] << List.singleton) <|
                Maybe.withDefault [] <|
                game.winningRoles
            , if isLeader
                then div [ class "w-finished-next-game", onClick onNewGame ]
                    [ text <| getSingle config.lang
                        [ "ui", "new-game" ]
                    ]
                else div [] []
            ]
        ]