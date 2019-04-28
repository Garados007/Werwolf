module Game.UI.ChatPostTile exposing (ChatPostTile,view)

import Html exposing (Html,div,text)
import Html.Attributes exposing (class)
import Time exposing (Posix, Zone)
import Game.Utils.Dates exposing (DateTimeFormat,convert)
import Game.Configuration exposing (..)
import Game.Utils.Language exposing (..)
import Game.Data exposing (Data)

type alias ChatPostTile =
    { userName: String
    , userId: Int
    , time: Posix
    , chat: String
    , chatId : Int
    , text: String
    , special: Maybe LangVars
    , id : Int
    }

view : Data -> LangLocal -> ChatPostTile -> Html msg
view data lang post = 
    div [ class "chat-post-tile" ]
        [ div [ class "chat-post-tile-header" ]
            [ div [ class "chat-post-tile-user" ]
                [ text post.userName ]
            , div [ class "chat-post-tile-chat" ]
                [ text <| chatName lang post.chat ]
            , div [ class "chat-post-tile-time" ]
                [ text (convert data.config.chatDateFormat post.time data.time.zone) ]
            ]
        , div [ class "chat-post-tile-text" ]
            [ case post.special of
                Nothing -> text post.text 
                Just vars -> text <| getSpecial lang vars
            ]
        ]

chatName : LangLocal -> String -> String
chatName lang chat =
    if String.contains "#" chat
    then chat
    else getChatName lang chat