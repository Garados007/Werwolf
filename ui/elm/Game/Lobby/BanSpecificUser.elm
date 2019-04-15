module Game.Lobby.BanSpecificUser exposing
    ( BanSpecificUser
    , BanSpecificUserMsg
    , msgSetConfig
    , msgSetUser
    , BanSpecificUserEvent (..)
    , BanSpecificUserDef
    , banSpecificUserModule
    )
    
import ModuleConfig as MC exposing (..)

import Game.Configuration exposing (..)
import Game.Utils.Language exposing (..)
import Config exposing (..)
import Game.Lobby.ModalWindow exposing (modal)
import Game.Types.Request exposing (..)

import Html exposing (Html,div,text,a,img,input,node)
import Html.Attributes exposing (class,attribute,href,value,type_,checked,selected)
import Html.Events exposing (onInput,onClick,on)
import Json.Decode as Json
import Regex exposing (Regex)

-- elm/core
import Task

-- elm/time
import Time exposing (Posix, Zone, posixToMillis, posixToMillis, utc, here)

-- justinmimbs/time-extra
import Time.Extra exposing (Interval (..), Parts, add, partsToPosix, posixToParts)

regex : String -> Regex 
regex = Maybe.withDefault Regex.never
    << Regex.fromString

type BanSpecificUser = BanSpecificUser BanSpecificUserInfo

type alias Request = Game.Types.Request.Response

type alias BanSpecificUserInfo =
    { config : LangConfiguration
    , ban : BanMode
    , now : Posix
    , zone : Zone
    , comment : String
    , user : Int
    , group : Int
    }

type BanSpecificUserMsg
    -- public Methods
    = SetConfig LangConfiguration
    | SetUser Int Int --user group
    -- private Methods
    | OnClose
    | OnChangeMode BanMode
    | NewTime Posix
    | NewZone Zone
    | OnCreate
    | OnInput String

type BanSpecificUserEvent
    = Close
    | Create Request

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

msgSetConfig : LangConfiguration -> BanSpecificUserMsg
msgSetConfig = SetConfig

msgSetUser : Int -> Int -> BanSpecificUserMsg 
msgSetUser user group = SetUser user group

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
        , now = Time.millisToPosix 0
        , zone = utc
        , comment = ""
        , user = 0
        , group = 0
        }
    , Task.perform NewZone here
    , []
    )

update : BanSpecificUserDef a -> BanSpecificUserMsg -> BanSpecificUser -> (BanSpecificUser, Cmd BanSpecificUserMsg, List a)
update def msg (BanSpecificUser model) = case msg of
    SetConfig config ->
        ( BanSpecificUser { model | config = config }
        , Cmd.none
        , []
        )
    SetUser user group ->
        ( BanSpecificUser 
            { model 
            | user = user
            , group = group 
            , comment = ""
            }
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
    NewZone zone ->
        ( BanSpecificUser { model | zone = zone }
        , Cmd.none
        , []
        )
    OnCreate ->
        ( BanSpecificUser model
        , Cmd.none
        , event def <| Create <| Debug.log "BanSpecificUser:OnCreate" <| getRequest model
        )
    OnInput text ->
        ( BanSpecificUser { model | comment = text }
        , Cmd.none
        , []
        )

getRequest : BanSpecificUserInfo -> Request
getRequest info = RespControl <| case info.ban of
    Kick -> KickUser info.user info.group
    TimeBan unit time ->
        let fact = case unit of
                BTUMinute -> 60 * 1000
                BTUHour -> 60 * 60 * 1000
                BTUDays -> 24 * 60 * 60 * 1000
            target = add Millisecond (round <| fact * time) info.zone info.now
        in BanUser info.user info.group 
            ((posixToMillis target) // 1000) 
            info.comment
    DateBan d m y h min ->
        let date = partsToPosix info.zone
                <| Parts y (numMonth m) d h min 0 0
        in BanUser info.user info.group 
            ((posixToMillis date) // 1000)
            info.comment
    Perma -> BanUser info.user info.group -1 info.comment

monthNum : Time.Month -> Int
monthNum month = case month of
    Time.Jan -> 1
    Time.Feb -> 2
    Time.Mar -> 3
    Time.Apr -> 4
    Time.May -> 5
    Time.Jun -> 6
    Time.Jul -> 7
    Time.Aug -> 8
    Time.Sep -> 9
    Time.Oct -> 10
    Time.Nov -> 11
    Time.Dec -> 12

numMonth : Int -> Time.Month 
numMonth num = case num of 
    1 -> Time.Jan
    2 -> Time.Feb
    3 -> Time.Mar
    4 -> Time.Apr 
    5 -> Time.May 
    6 -> Time.Jun
    7 -> Time.Jul 
    8 -> Time.Aug 
    9 -> Time.Sep 
    10 -> Time.Oct
    11 -> Time.Nov 
    12 -> Time.Dec
    -- Fallback
    _ -> Time.Jan

single : BanSpecificUserInfo -> String -> String
single info key = getSingle info.config.lang [ "lobby", "bsu", key ]

view : BanSpecificUser -> Html BanSpecificUserMsg
view (BanSpecificUser model) = 
    modal OnClose (single model "ban-specific-user") <|
        div [ class "w-banuser-box" ] 
            [ viewRadios model
            , case model.ban of
                Kick -> viewKick model
                TimeBan unit duration -> viewTimeBan model unit duration
                DateBan d m y h min -> viewDateBan model d m y h min
                Perma -> viewPerma model
            , if model.ban /= Kick
                then node "textarea"
                    [ onInput OnInput
                    , attribute "placeholder" <|
                        single model "description"
                    , attribute "pattern" "^.{5,1000}$"
                    ]
                    [ text model.comment ]
                else text ""
            , if (model.ban == Kick) || (Regex.contains (regex "^.{5,1000}$") model.comment)
                then div
                    [ class "w-banuser-create"
                    , onClick OnCreate
                    ]
                    [ text <| single model "create" ]
                else text ""
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
        [ radio "kick" (OnChangeMode Kick) <| info.ban == Kick
        , radio "timeban" (OnChangeMode <| TimeBan BTUHour 5) <| case info.ban of
            TimeBan _ _ -> True
            _ -> False
        , radio "dateban" 
            ( OnChangeMode <| (\p ->
                DateBan p.day (monthNum p.month) p.year p.hour p.minute
            ) <| posixToParts info.zone info.now) 
            <| case info.ban of
                DateBan _ _ _ _ _ -> True
                _ -> False
        , radio "perma" (OnChangeMode Perma) <| info.ban == Perma
        ]

viewKick : BanSpecificUserInfo -> Html BanSpecificUserMsg
viewKick info = div [ class "w-ban-user-conf kick" ]
    [ text <| single info "info-kick" ]

viewTimeBan : BanSpecificUserInfo -> BanTypeUnit -> Float -> Html BanSpecificUserMsg
viewTimeBan info unit duration =
    let
        inp : Float -> (Float -> BanMode) -> Html BanSpecificUserMsg
        inp = \val event ->
            input
                [ type_ "number"
                , attribute "min" "0"
                , value <| String.fromFloat val
                , attribute "step" "0.001"
                , onInput <| OnChangeMode 
                    << event
                    << Maybe.withDefault val
                    << String.toFloat
                ] []
        flip : (a -> b -> c) -> b -> a -> c
        flip f b a = f a b
    in div [ class "w-banuser-conf timeban" ]
        [ div [] <| List.singleton <| inp duration (TimeBan unit)
        , div [] <| List.singleton <| node "select"
            [ on "change" <| Json.map (\u -> OnChangeMode <| flip TimeBan duration <| case u of
                    "m" -> BTUMinute
                    "h" -> BTUHour
                    "d" -> BTUDays
                    _ -> Debug.todo <| "BanSpecificUser:viewTimeBan - unknown unit format " ++ u
                ) Html.Events.targetValue
            ] <| List.map
            (\(f,k) -> node "option"
                [ value k
                , selected <| f == unit
                ]
                [ text <| single info <| "timeunit-" ++ k ]
            )
            [ (BTUMinute, "m")
            , (BTUHour, "h")
            , (BTUDays, "d")
            ]
        ]
        
viewDateBan : BanSpecificUserInfo -> Int -> Int -> Int -> Int -> Int -> Html BanSpecificUserMsg
viewDateBan info day month year hour minute =
    let inp : Int -> Int -> Int -> (Int -> BanMode) -> Html BanSpecificUserMsg
        inp = \val min max event ->
            input
                [ type_ "number"
                , attribute "min" <| String.fromInt min
                , attribute "max" <| String.fromInt max
                , value <| String.fromInt val
                , onInput <| OnChangeMode 
                    << event 
                    << Maybe.withDefault val 
                    << String.toInt
                ] []
        part : String -> Int -> Int -> Int -> (Int -> BanMode) -> Html BanSpecificUserMsg
        part = \labelKey val min max event ->
            div []
                [ div [] [ text <| single info labelKey ]
                , div [] [ inp val min max event ]
                ]
    in div [ class "w-ban-user-conf dateban" ]
        [ part "day" day 1 (dayMax month year) <| \v -> DateBan v month year hour minute
        , part "month" month 1 12 <| \v -> DateBan (min day <| dayMax v year) v year hour minute
        , part "year" year 2018 2100 <| \v -> DateBan (min day <| dayMax month v) month v hour minute
        , part "hour" hour 0 23 <| \v -> DateBan day month year v minute
        , part "minute" minute 0 59 <| \v -> DateBan day month year hour v
        ]

dayMax : Int -> Int -> Int
dayMax month year =
    if month == 2
    then if (modBy 4 year == 0) && ((modBy 100 year /= 0) || (modBy 400 year == 0))
        then 29
        else 28
    else if xor (month <= 7) (modBy 2 month == 0)
        then 31
        else 30

viewPerma : BanSpecificUserInfo -> Html BanSpecificUserMsg
viewPerma info = div [ class "w-ban-user-conf perma"] 
    [ text <| single info "info-perma" ]

subscriptions : BanSpecificUser -> Sub BanSpecificUserMsg
subscriptions (BanSpecificUser model) =
    if model.now == Time.millisToPosix 0
    then Time.every 1000 NewTime
    else Time.every 20000 NewTime