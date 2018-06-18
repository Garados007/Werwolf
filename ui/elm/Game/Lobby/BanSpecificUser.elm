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
import Html.Attributes exposing (class,attribute,href,value,type_,checked,selected)
import Html.Events exposing (onInput,onClick,on)
import Time exposing (Time)
import Date
import Json.Decode as Json

type BanSpecificUser = BanSpecificUser BanSpecificUserInfo

type alias BanSpecificUserInfo =
    { config : LangConfiguration
    , ban : BanMode
    , now : Time
    }

type BanSpecificUserMsg
    -- public Methods
    = SetConfig LangConfiguration
    -- private Methods
    | OnClose
    | OnChangeMode BanMode
    | NewTime Time
    | OnCreate

type BanSpecificUserEvent
    = Close

type BanTypeUnit
    = BTUMinute
    | BTUHour
    | BTUDays

type BanMode
    = Kick
    | TimeBan BanTypeUnit Float
    | DateBan Int Int Int Int Int -- day month year, hour minute
    | Perma

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
        , now = 0
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
    NewTime time ->
        ( BanSpecificUser { model | now = time }
        , Cmd.none
        , []
        )
    OnCreate ->
        ( BanSpecificUser model
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
            , case model.ban of
                Kick -> viewKick model
                TimeBan unit duration -> viewTimeBan model unit duration
                DateBan d m y h min -> viewDateBan model d m y h min
                Perma -> viewPerma model
            , div
                [ class "w-banuser-create"
                , onClick OnCreate
                ]
                [ text <| single model "bsu-create" ]
            ]

viewRadios : BanSpecificUserInfo -> Html BanSpecificUserMsg
viewRadios info =
    let radio : String -> BanSpecificUserMsg -> Bool -> Html BanSpecificUserMsg
        radio = \labelKey event clicked ->
            node "label" []
                [ input
                    [ type_ "radio"
                    , checked clicked
                    , onClick event
                    ] []
                , text <| single info labelKey
                ]
    in div [ class "w-banuser-radios" ]
        [ radio "bsu-kick" (OnChangeMode Kick) <| info.ban == Kick
        , radio "bsu-timeban" (OnChangeMode <| TimeBan BTUHour 5) <| case info.ban of
            TimeBan _ _ -> True
            _ -> False
        , radio "bsu-dateban" 
            ( OnChangeMode <| (\(d,m,y,h,min) ->
                DateBan d m y h min
            ) <| split info.now) 
            <| case info.ban of
                DateBan _ _ _ _ _ -> True
                _ -> False
        , radio "bsu-perma" (OnChangeMode Perma) <| info.ban == Perma
        ]

viewKick : BanSpecificUserInfo -> Html BanSpecificUserMsg
viewKick info = div [ class "w-ban-user-conf kick" ]
    [ text <| single info "bsu-info-kick" ]

viewTimeBan : BanSpecificUserInfo -> BanTypeUnit -> Float -> Html BanSpecificUserMsg
viewTimeBan info unit duration =
    let
        inp : Float -> (Float -> BanMode) -> Html BanSpecificUserMsg
        inp = \val event ->
            input
                [ type_ "number"
                , attribute "min" "0"
                , value <| toString val
                , attribute "step" "0.001"
                , onInput <| OnChangeMode << event << (\v -> case String.toFloat v of
                        Ok n -> n
                        Err _ -> val
                    )
                ] []
    in div [ class "w-banuser-conf timeban" ]
        [ div [] <| List.singleton <| inp duration (TimeBan unit)
        , div [] <| List.singleton <| node "select"
            [ on "change" <| Json.map (\u -> OnChangeMode <| flip TimeBan duration <| case u of
                    "m" -> BTUMinute
                    "h" -> BTUHour
                    "d" -> BTUDays
                    _ -> Debug.crash <| "BanSpecificUser:viewTimeBan - unknown unit format " ++ u
                ) Html.Events.targetValue
            ] <| List.map
            (\(f,k) -> node "option"
                [ value k
                , selected <| f == unit
                ]
                [ text <| single info <| "bsu-timeunit-" ++ k ]
            )
            [ (BTUMinute, "m")
            , (BTUHour, "h")
            , (BTUDays, "d")
            ]
        ]
        
viewDateBan : BanSpecificUserInfo -> Int -> Int -> Int -> Int -> Int -> Html BanSpecificUserMsg
viewDateBan info day month year hour minute =
    let inp : Int -> Int -> (Int -> BanMode) -> Html BanSpecificUserMsg
        inp = \val max event ->
            input
                [ type_ "number"
                , attribute "min" "0"
                , attribute "max" <| toString max
                , value <| toString val
                , onInput <| OnChangeMode << event << (\v -> case String.toInt v of
                        Ok n -> n
                        Err _ -> val
                    )
                ] []
        part : String -> Int -> Int -> (Int -> BanMode) -> Html BanSpecificUserMsg
        part = \labelKey val max event ->
            div []
                [ div [] [ text <| single info labelKey ]
                , div [] [ inp val max event ]
                ]
    in div [ class "w-ban-user-conf dateban" ]
        [ part "bsu-day" day 31 <| \v -> DateBan v month year hour minute
        , part "bsu-month" month 12 <| \v -> DateBan day v year hour minute
        , part "bsu-year" year 2100 <| \v -> DateBan day month v hour minute
        , part "bsu-hour" hour 24 <| \v -> DateBan day month year v minute
        , part "bsu-minute" minute 60 <| \v -> DateBan day month year hour v
        ]

viewPerma : BanSpecificUserInfo -> Html BanSpecificUserMsg
viewPerma info = div [ class "w-ban-user-conf perma"] 
    [ text <| single info "bsu-info-perma" ]

split : Time -> (Int, Int, Int, Int, Int) --day,month,year,hour,minute
split time =
    let date = Date.fromTime <| time + (Time.hour * 4)
    in  ( Date.day date
        , case Date.month date of
            Date.Jan -> 1
            Date.Feb -> 2
            Date.Mar -> 3
            Date.Apr -> 4
            Date.May -> 5
            Date.Jun -> 6
            Date.Jul -> 7
            Date.Aug -> 8
            Date.Sep -> 9
            Date.Oct -> 10
            Date.Nov -> 11
            Date.Dec -> 12
        , Date.year date
        , Date.hour date
        , Date.minute date
        )


subscriptions : BanSpecificUser -> Sub BanSpecificUserMsg
subscriptions (BanSpecificUser model) =
    if model.now == 0
    then Time.every Time.second NewTime
    else Time.every (Time.second*20) NewTime