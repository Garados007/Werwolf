module Game.Lobby.JoinGroup exposing
    ( JoinGroup
    , JoinGroupMsg
    , JoinGroupEvent (..)
    , JoinGroupDef
    , joinGroupModule
    , getKey
    , msgSetConfig
    , msgInvalidKey
    , msgUserBanned
    )
    
import ModuleConfig as MC exposing (..)

import Game.Configuration exposing (..)
import Game.Utils.Language exposing (..)
import Config exposing (..)
import Game.Lobby.ModalWindow exposing (modal)

import Html exposing (Html,div,text,a,img,input)
import Html.Attributes exposing (class,attribute,href,value)
import Html.Events exposing (onInput,onClick)
import Regex exposing (Regex)

regex : String -> Regex
regex = Maybe.withDefault Regex.never
    << Regex.fromString

type JoinGroup = JoinGroup JoinGroupInfo

type alias JoinGroupInfo =
    { config : LangConfiguration
    , key : String
    , invalid : Bool
    , banned : Bool
    }

type JoinGroupMsg
    -- public Methods
    = SetConfig LangConfiguration
    | InvalidKey
    | UserBanned
    -- private Methods
    | OnClose
    | OnChangeKey String
    | OnJoin

type JoinGroupEvent
    = Close
    | Join String

type alias JoinGroupDef a = ModuleConfig JoinGroup JoinGroupMsg
    () JoinGroupEvent a

msgSetConfig : LangConfiguration -> JoinGroupMsg
msgSetConfig = SetConfig

msgInvalidKey : JoinGroupMsg
msgInvalidKey = InvalidKey

msgUserBanned : JoinGroupMsg
msgUserBanned = UserBanned

joinGroupModule : (JoinGroupEvent -> List a) ->
    (JoinGroupDef a, Cmd JoinGroupMsg, List a)
joinGroupModule event = createModule
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }
    event ()

init : () -> (JoinGroup, Cmd JoinGroupMsg, List a)
init () =
    ( JoinGroup
        { config = LangConfiguration empty <|
            createLocal (newGlobal lang_backup) Nothing
        , key = ""
        , invalid = False
        , banned = False
        }
    , Cmd.none
    , []
    )

update : JoinGroupDef a -> JoinGroupMsg -> JoinGroup -> (JoinGroup, Cmd JoinGroupMsg, List a)
update def msg (JoinGroup model) = case msg of
    SetConfig config ->
        ( JoinGroup { model | config = config }
        , Cmd.none
        , []
        )
    InvalidKey ->
        ( JoinGroup { model | invalid = True }
        , Cmd.none
        , []
        )
    UserBanned ->
        ( JoinGroup { model | banned = True }
        , Cmd.none
        , []
        )
    OnClose ->
        ( JoinGroup model
        , Cmd.none
        , event def Close
        )
    OnChangeKey key ->
        ( JoinGroup { model | key = key, invalid = False, banned = False }
        , Cmd.none
        , []
        )
    OnJoin ->
        ( JoinGroup model
        , Cmd.none
        , event def <| Join <| shortenKey model.key
        )

keypattern : String
keypattern = "^\\s*([0-9A-HJ-NP-UW-Za-hj-np-uw-z]\\s*){12}$"

shortenKey : String -> String
shortenKey = Regex.replace (regex "\\s") (always "")

view : JoinGroup -> Html JoinGroupMsg
view (JoinGroup model) = 
    let invKey = if model.invalid
            then "key-not-exists"
            else if model.banned
                then "user-banned"
                else if Regex.contains (regex keypattern) model.key
                    then ""
                    else "invalid-key-pattern"
    in modal OnClose (getSingle model.config.lang ["lobby", "join-group" ]) <|
        div [ class "w-joingroup-box" ] 
            [ text <| getSingle model.config.lang ["lobby", "join-group-key"]
            , input
                [ attribute "type" "text"
                , attribute "pattern" keypattern
                , value model.key
                , onInput OnChangeKey
                ] []
            , if invKey /= ""
                then text <| getSingle model.config.lang ["lobby", invKey ]
                else div 
                    [ class "w-joingroup-submit"
                    , onClick OnJoin
                    ]
                    [ text <| getSingle model.config.lang ["lobby", "on-join-group" ]
                    ]
            ]

subscriptions : JoinGroup -> Sub JoinGroupMsg
subscriptions (JoinGroup model) =
    Sub.none

getKey : JoinGroup -> String
getKey (JoinGroup model) = shortenKey model.key