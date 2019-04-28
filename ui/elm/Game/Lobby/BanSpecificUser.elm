module Game.Lobby.BanSpecificUser exposing
    ( BanSpecificUser
    , BanSpecificUserMsg
    , BanSpecificUserEvent (..)
    , init
    , view
    , update
    )

import Game.Utils.Language exposing (..)
import Game.Lobby.ModalWindow exposing (modal)
import Game.Types.Types as Types exposing (..)
import Game.Types.Request exposing (..)
import Game.Data as Data exposing (..)

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

type alias BanSpecificUserInfo =
    { ban : BanMode
    , comment : String
    , user : UserId
    , group : GroupId
    }

type BanSpecificUserMsg
    -- public Methods
    -- private Methods
    = OnClose
    | OnChangeMode BanMode
    | OnCreate
    | OnInput String
    | OnEvent (List BanSpecificUserEvent)

type BanSpecificUserEvent
    = Close
    | Create Request
    | ReqData (Data -> BanSpecificUserMsg)

type BanTypeUnit
    = BTUMinute
    | BTUHour
    | BTUDays

type BanMode
    = Kick
    | TimeBan BanTypeUnit Float
    | DateBan Int Int Int Int Int -- day month year, hour minute
    | Perma

init : UserId -> GroupId -> BanSpecificUser
init user group = BanSpecificUser
    { ban = Kick
    , comment = ""
    , user = user
    , group = group
    }

update : BanSpecificUserMsg -> BanSpecificUser -> (BanSpecificUser, Cmd BanSpecificUserMsg, List BanSpecificUserEvent)
update msg (BanSpecificUser model) = case msg of
    OnClose ->
        ( BanSpecificUser model
        , Cmd.none
        , [ Close ]
        )
    OnChangeMode mode ->
        ( BanSpecificUser { model | ban = mode }
        , Cmd.none
        , []
        )
    OnCreate ->
        ( BanSpecificUser model
        , Cmd.none
        , List.singleton 
            <| ReqData
            (\data -> OnEvent
                <| List.singleton
                <| Create 
                <| getRequest data model
            )
        )
    OnEvent list ->
        ( BanSpecificUser model 
        , Cmd.none 
        , []
        )
    OnInput text ->
        ( BanSpecificUser { model | comment = text }
        , Cmd.none
        , []
        )

getRequest : Data -> BanSpecificUserInfo -> Request
getRequest data info = ReqControl <| case info.ban of
    Kick -> KickUser info.user info.group
    TimeBan unit time ->
        let fact = case unit of
                BTUMinute -> 60 * 1000
                BTUHour -> 60 * 60 * 1000
                BTUDays -> 24 * 60 * 60 * 1000
            target : Posix
            target = add 
                Millisecond 
                (round <| fact * time) 
                data.time.zone 
                data.time.now
        in BanUser info.user info.group target
            info.comment
    DateBan d m y h min ->
        let date = partsToPosix data.time.zone
                <| Parts y (numMonth m) d h min 0 0
        in BanUser info.user info.group date
            info.comment
    Perma -> BanUser info.user info.group (Time.millisToPosix -1000) info.comment

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

single : LangLocal -> BanSpecificUserInfo -> String -> String
single lang info key = getSingle lang [ "lobby", "bsu", key ]

view : Data -> LangLocal -> BanSpecificUser -> Html BanSpecificUserMsg
view data lang (BanSpecificUser model) = 
    modal OnClose (single lang model "ban-specific-user") <|
        div [ class "w-banuser-box" ] 
            [ viewRadios data lang model
            , case model.ban of
                Kick -> viewKick lang model
                TimeBan unit duration -> viewTimeBan lang model unit duration
                DateBan d m y h min -> viewDateBan lang model d m y h min
                Perma -> viewPerma lang model
            , if model.ban /= Kick
                then node "textarea"
                    [ onInput OnInput
                    , attribute "placeholder" <|
                        single lang  model "description"
                    , attribute "pattern" "^.{5,1000}$"
                    ]
                    [ text model.comment ]
                else text ""
            , if (model.ban == Kick) || (Regex.contains (regex "^.{5,1000}$") model.comment)
                then div
                    [ class "w-banuser-create"
                    , onClick OnCreate
                    ]
                    [ text <| single lang model "create" ]
                else text ""
            ]

viewRadios : Data -> LangLocal -> BanSpecificUserInfo -> Html BanSpecificUserMsg
viewRadios data lang info =
    let radio : String -> BanSpecificUserMsg -> Bool -> Html BanSpecificUserMsg
        radio = \labelKey event clicked ->
            node "label" []
                [ input
                    [ type_ "radio"
                    , checked clicked
                    , onClick event
                    ] []
                , text <| single lang info labelKey
                ]
    in div [ class "w-banuser-radios" ]
        [ radio "kick" (OnChangeMode Kick) <| info.ban == Kick
        , radio "timeban" (OnChangeMode <| TimeBan BTUHour 5) <| case info.ban of
            TimeBan _ _ -> True
            _ -> False
        , radio "dateban" 
            ( OnChangeMode <| (\p ->
                DateBan p.day (monthNum p.month) p.year p.hour p.minute
            ) <| posixToParts data.time.zone data.time.now) 
            <| case info.ban of
                DateBan _ _ _ _ _ -> True
                _ -> False
        , radio "perma" (OnChangeMode Perma) <| info.ban == Perma
        ]

viewKick : LangLocal -> BanSpecificUserInfo -> Html BanSpecificUserMsg
viewKick lang info = div [ class "w-ban-user-conf kick" ]
    [ text <| single lang info "info-kick" ]

viewTimeBan : LangLocal -> BanSpecificUserInfo -> BanTypeUnit -> Float -> Html BanSpecificUserMsg
viewTimeBan lang info unit duration =
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
                [ text <| single lang info <| "timeunit-" ++ k ]
            )
            [ (BTUMinute, "m")
            , (BTUHour, "h")
            , (BTUDays, "d")
            ]
        ]
        
viewDateBan : LangLocal -> BanSpecificUserInfo -> Int -> Int -> Int -> Int -> Int -> Html BanSpecificUserMsg
viewDateBan lang info day month year hour minute =
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
                [ div [] [ text <| single lang info labelKey ]
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

viewPerma : LangLocal -> BanSpecificUserInfo -> Html BanSpecificUserMsg
viewPerma lang info = div [ class "w-ban-user-conf perma"] 
    [ text <| single lang info "info-perma" ]
