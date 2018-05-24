module Game.UI.ChatPostTile exposing (ChatPostTile,view)

import Html exposing (program,Html,div,text)
import Html.Attributes exposing (class)
import Time exposing (Time)
import Game.Utils.Dates exposing (DateTimeFormat,convert)
import Game.Configuration exposing (..)
import Game.Utils.Language exposing (..)

type alias ChatPostTile =
    { userName: String
    , userId: Int
    , time: Time
    , chat: String
    , chatId : Int
    , text: String
    }

view : LangConfiguration -> ChatPostTile -> Html msg
view config post = 
    div [ class "chat-post-tile" ]
        [ div [ class "chat-post-tile-header" ]
            [ div [ class "chat-post-tile-user" ]
                [ text post.userName ]
            , div [ class "chat-post-tile-chat" ]
                [ text <| chatName config post.chat ]
            , div [ class "chat-post-tile-time" ]
                [ text (convert config.conf.chatDateFormat post.time) ]
            ]
        , div [ class "chat-post-tile-text" ]
            [ text post.text ]
        ]

chatName : LangConfiguration -> String -> String
chatName config chat =
    if String.contains "#" chat
    then chat
    else getChatName config.lang chat