module Game.UI.ChatPostTile exposing (ChatPostTile,view)

import Html exposing (program,Html,div,text)
import Html.Attributes exposing (class)
import Time exposing (Time)
import Game.Utils.Dates exposing (DateTimeFormat,convert)

main : Program Never ChatPostTile msg
main = program
    { init = (ChatPostTile "Testuser" 50000
        "test-room" "this is a test chat" 
        Game.Utils.Dates.DD_MM_YYYY_H24_M_S, Cmd.none)
    , view = view
    , update = \msg model -> (model, Cmd.none)
    , subscriptions = \model -> Sub.none
    }

type alias ChatPostTile =
    { userName: String
    , time: Time
    , chat: String
    , text: String
    , format: DateTimeFormat
    }

view : ChatPostTile -> Html msg
view post =
    div [ class "chat-post-tile" ]
        [ div [ class "chat-post-tile-header" ]
            [ div [ class "chat-post-tile-user" ]
                [ text post.userName ]
            , div [ class "chat-post-tile-chat" ]
                [ text post.chat ]
            , div [ class "chat-post-tile-time" ]
                [ text (convert post.format post.time) ]
            ]
        , div [ class "chat-post-tile-text" ]
            [ text post.text ]
        ]