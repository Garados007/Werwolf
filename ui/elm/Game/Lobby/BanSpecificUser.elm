module Game.Lobby.BanSpecificUser exposing
    ( BanSpecificUser
    , BanSpecificUserMsg
        ( SetConfig
        )
    , BanSpecificUserEvent (..)
    , BanSpecificUserDef
    , banSpecificUserModule
    )
    
import ModuleConfig as MC exposing (..)

import Game.Configuration exposing (..)
import Game.Utils.Language exposing (..)
import Config exposing (..)
import Game.Lobby.ModalWindow exposing (modal)

import Html exposing (Html,div,text,a,img,input)
import Html.Attributes exposing (class,attribute,href,value)
import Html.Events exposing (onInput,onClick)

type BanSpecificUser = BanSpecificUser BanSpecificUserInfo

type alias BanSpecificUserInfo =
    { config : LangConfiguration
    }

type BanSpecificUserMsg
    -- public Methods
    = SetConfig LangConfiguration
    -- private Methods
    | OnClose

type BanSpecificUserEvent
    = Close

type alias BanSpecificUserDef a = ModuleConfig BanSpecificUser BanSpecificUserMsg
    () BanSpecificUserEvent a

banSpecificUserModule : (BanSpecificUserEvent -> List a) ->
    (BanSpecificUserDef a, Cmd BanSpecificUserMsg, List a)
banSpecificUserModule event = createModule
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }
    event ()

init : () -> (BanSpecificUser, Cmd BanSpecificUserMsg, List a)
init () =
    ( BanSpecificUser
        { config = LangConfiguration empty <|
            createLocal (newGlobal lang_backup) Nothing
        }
    , Cmd.none
    , []
    )

update : BanSpecificUserDef a -> BanSpecificUserMsg -> BanSpecificUser -> (BanSpecificUser, Cmd BanSpecificUserMsg, List a)
update def msg (BanSpecificUser model) = case msg of
    SetConfig config ->
        ( BanSpecificUser { model | config = config }
        , Cmd.none
        , []
        )
    OnClose ->
        ( BanSpecificUser model
        , Cmd.none
        , event def Close
        )

view : BanSpecificUser -> Html BanSpecificUserMsg
view (BanSpecificUser model) = 
    modal OnClose (getSingle model.config.lang ["lobby", "ban-specific-user" ]) <|
        div [ class "w-joingroup-box" ] 
            [ 
            ]

subscriptions : BanSpecificUser -> Sub BanSpecificUserMsg
subscriptions (BanSpecificUser model) =
    Sub.none