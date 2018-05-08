module Game.UI.ChatLog exposing 
    ( ChatTile (..)
    , ChatLog
    , view
    , Msg (Add)
    )

import Dom
import Dom.Scroll exposing (toBottom)
import Html exposing (program,Html,div)
import Html.Attributes exposing (class,id)
import List
import Task exposing (perform,attempt)

import Game.UI.ChatPostTile as ChatPostTile
import Game.Utils.Dates

main : Program Never ChatLog Msg
main = program
    { init = (init "test", 
        perform Add (
            Task.succeed (
                PostTile (
                    ChatPostTile.ChatPostTile
                        "Testuser" 
                        50000
                        "test-room" 
                        "this is a test chat" 
                        Game.Utils.Dates.DD_MM_YYYY_H24_M_S
                )
            )
        )
    )
    , view = view
    , update = update
    , subscriptions = \_ -> Sub.none
    }

type ChatTile
    = PostTile ChatPostTile.ChatPostTile

type ChatLog = Internal IntChatLog

type alias IntChatLog =
    { id : String
    , items : List ChatTile
    }

type Msg
    = Add ChatTile
    | NoOp1 (Result Dom.Error ())

init : String -> ChatLog
init id = Internal (IntChatLog id [])

view : ChatLog -> Html Msg
view (Internal log) =
    div [ class "chat-log", id log.id ]
        (List.map viewTile log.items)

viewTile : ChatTile -> Html msg
viewTile tile =
    case tile of
        PostTile tile -> ChatPostTile.view tile

update : Msg -> ChatLog -> (ChatLog, Cmd Msg)
update msg (Internal model) =
    case msg of
        Add tile ->
            let
                list = List.append model.items [ tile ]
                cmd = attempt NoOp1 (toBottom model.id)
            in (Internal { model | items = list }, cmd)
        NoOp1 _ -> (Internal model, Cmd.none)