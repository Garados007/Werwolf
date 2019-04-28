module Game.Lobby.JoinGroup exposing
    ( JoinGroup
    , JoinGroupMsg
    , JoinGroupEvent (..)
    , detector
    , init
    , view
    , update
    )

import Game.Utils.Language exposing (..)
import Game.Lobby.ModalWindow exposing (modal)
import Game.Data as Data exposing (..)
import DataDiff.Path as Diff exposing (DetectorPath, Path (..))
import DataDiff.Ex exposing (SingleActionEx (..), ModActionEx (..))

import Html exposing (Html,div,text,a,img,input)
import Html.Attributes exposing (class,attribute,href,value)
import Html.Events exposing (onInput,onClick)
import Regex exposing (Regex)
import Dict
import Time exposing (Posix)

regex : String -> Regex
regex = Maybe.withDefault Regex.never
    << Regex.fromString

type JoinGroup = JoinGroup JoinGroupInfo

type alias JoinGroupInfo =
    { key : String
    }

type JoinGroupMsg
    -- public Methods
    -- private Methods
    = OnClose
    | OnChangeKey String
    | OnJoin
    | NoOp

type JoinGroupEvent
    = Close
    | Join String

detector : JoinGroup -> DetectorPath Data JoinGroupMsg
detector (JoinGroup model) = Data.pathGameData
    <| Data.pathGroupData 
        [ AddedEx <| \_ g ->
            if g.group.enterKey == shortenKey model.key 
            then OnClose 
            else NoOp
        ]
    <| Diff.noOp

init : JoinGroup
init = JoinGroup
    { key = ""
    }

update : JoinGroupMsg -> JoinGroup -> (JoinGroup, Cmd JoinGroupMsg, List JoinGroupEvent)
update msg (JoinGroup model) = case msg of
    OnClose ->
        ( JoinGroup model
        , Cmd.none
        , [ Close ]
        )
    OnChangeKey key ->
        ( JoinGroup { model | key = key }
        , Cmd.none
        , []
        )
    OnJoin ->
        ( JoinGroup model
        , Cmd.none
        , [ Join <| shortenKey model.key ]
        )
    NoOp -> ( JoinGroup model, Cmd.none, [])

keypattern : String
keypattern = "^\\s*([0-9A-HJ-NP-UW-Za-hj-np-uw-z]\\s*){12}$"

shortenKey : String -> String
shortenKey = Regex.replace (regex "\\s") (always "")

view : Data -> LangLocal -> JoinGroup -> Html JoinGroupMsg
view data lang (JoinGroup model) = 
    let invalid : Maybe Posix
        invalid = Dict.get model.key data.game.invalidGroups
        banned : Maybe Posix
        banned = Dict.get model.key data.game.bannedGroups
        invKey = if invalid /= Nothing
            then "key-not-exists"
            else if banned /= Nothing
                then "user-banned"
                else if Regex.contains (regex keypattern) model.key
                    then ""
                    else "invalid-key-pattern"
    in modal OnClose (getSingle lang ["lobby", "join-group" ])
        <| div 
            [ class "w-joingroup-box" ] 
            [ text <| getSingle lang ["lobby", "join-group-key"]
            , input
                [ attribute "type" "text"
                , attribute "pattern" keypattern
                , value model.key
                , onInput OnChangeKey
                ] []
            , if invKey /= ""
                then text <| getSingle lang ["lobby", invKey ]
                else div 
                    [ class "w-joingroup-submit"
                    , onClick OnJoin
                    ]
                    [ text <| getSingle lang ["lobby", "on-join-group" ]
                    ]
            ]
