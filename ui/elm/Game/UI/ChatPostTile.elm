module Game.UI.ChatPostTile exposing (ChatPostTile,view)

import Html exposing (Html,div,text)
import Html.Attributes exposing (class)
import Time exposing (Posix, Zone)
import Game.Utils.Dates exposing (DateTimeFormat,convert)
import Game.Configuration exposing (..)
import Game.Utils.Language exposing (..)

type alias ChatPostTile =
    { userName: String
    , userId: Int
    , time: Posix
    , zone: Zone
    , chat: String
    , chatId : Int
    , text: String
    , special: Maybe LangVars
    , id : Int
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
                [ text (convert config.conf.chatDateFormat post.time post.zone) ]
            ]
        , div [ class "chat-post-tile-text" ]
            [ case post.special of
                Nothing -> text post.text 
                Just vars -> text <| getSpecial config.lang vars
            ]
        ]

chatName : LangConfiguration -> String -> String
chatName config chat =
    if String.contains "#" chat
    then chat
    else getChatName config.lang chat