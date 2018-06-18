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

import Html exposing (Html,div,text,a,img,input,node)
import Html.Attributes exposing (class,attribute,href,value,type_,checked)
import Html.Events exposing (onInput,onClick)

type BanSpecificUser = BanSpecificUser BanSpecificUserInfo

type alias BanSpecificUserInfo =
    { config : LangConfiguration
    , ban : BanMode
    }

type BanSpecificUserMsg
    -- public Methods
    = SetConfig LangConfiguration
    -- private Methods
    | OnClose
    | OnChangeMode BanMode

type BanSpecificUserEvent
    = Close

type BanTypeUnit
    = BTUSecond
    | BTUMinute
    | BTUHour
    | BTUDays

type BanMode
    = Kick
    | TimeBan BanTypeUnit Float
    | DateBan Int Int Int Int Int -- day month year, hour minute

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
        , ban = Kick
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
    OnChangeMode mode ->
        ( BanSpecificUser { model | ban = mode }
        , Cmd.none
        , []
        )

single : BanSpecificUserInfo -> String -> String
single info key = getSingle info.config.lang [ "lobby", key ]

view : BanSpecificUser -> Html BanSpecificUserMsg
view (BanSpecificUser model) = 
    modal OnClose (getSingle model.config.lang ["lobby", "ban-specific-user" ]) <|
        div [ class "w-banuser-box" ] 
            [ viewRadios model
            ]

viewRadios : BanSpecificUserInfo -> Html BanSpecificUserMsg
viewRadios info =
    div [ class "w-banuser-radios" ]
        [ node "label" []
            [ input
                [ type_ "radio"
                , checked <| info.ban == Kick
                , onClick <| OnChangeMode Kick
                ] []
            , text <| single info "bsu-kick"
            ]
        , node "label" []
            [ input
                [ type_ "radio"
                , checked <| case info.ban of
                    TimeBan _ _ -> True
                    _ -> False
                , onClick <| OnChangeMode <| TimeBan BTUHour 5
                ] []
            , text <| single info "bsu-timeban"
            ]
        ]

subscriptions : BanSpecificUser -> Sub BanSpecificUserMsg
subscriptions (BanSpecificUser model) =
    Sub.none