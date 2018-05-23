module Test.TestLanguage exposing (main)

import Game.Utils.Language exposing (..)
import Game.Types.Types exposing (..)

import Html exposing (Html,text,program,div)
import Dict

langG : LangGlobal
langG = addMainLang (newGlobal "tl") "tl" sample

langL : LangLocal
langL = createLocal langG Nothing 
    |> flip updateUser [user]
    |> (flip updateChats <| Dict.fromList [(10,chat)] )

user : User
user = User 1 2 Nothing <| UserStat 2 "testuser" Nothing Nothing
    23 17 2 12345678 Nothing Nothing Nothing

chat : Chat
chat = Chat 10 7 "testChatRoom" 
    [ Voting 10 "testVoteKey" 12345678 Nothing Nothing [] [] Nothing
    ] <| Permission True True True []

sample : String
sample = """
{
    "key1": "text1",
    "key2": {
        "subkey1": "text2"
    },
    "specialKey1": [
        { "t": "text3 " },
        { "u": "user1" },
        { "t": " " },
        { "r": "room1" },
        { "t": " " },
        { "v": "voteKey1" }
    ],
    "chat-names": {
        "testChatRoom": "Test-Chat-Room"
    },
    "voting-names": {
        "testChatRoom": {
            "vk": "Test-Voting"
        }
    }
}
"""

special : String
special = """#json
{
    "key": [ "specialKey1" ],
    "user": {
        "user1": 2
    },
    "chat": {
        "room1": 10
    },
    "votes": {
        "voteKey1": [10, "vk"]
    }
}
"""

special2 : String
special2 = """#json[ "key1" ]"""

divs : String -> Html msg
divs = div [] << List.singleton << text

view : Html msg
view = div []
    [ divs <| getSingle langL [ "key1" ]
    , divs <| getSingle langL [ "key2", "subkey1" ]
    , divs <| toString <| Maybe.map (getSpecial langL) <| 
        decodeSpecial special
    , divs <| toString <| Maybe.map (getSpecial langL) <|
        decodeSpecial special2
    ]

main : Program Never () msg
main = program
    { init = ((), Cmd.none)
    , view = \() -> view
    , update = \_ m -> (m, Cmd.none)
    , subscriptions = \_ -> Sub.none
    }
