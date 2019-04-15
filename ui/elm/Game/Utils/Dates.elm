module Game.Utils.Dates exposing (DateTimeFormat (..), convert, all)

-- elm/time
import Time exposing 
    ( Posix
    , Zone
    , Month (..)
    , toDay
    , toHour
    , toMinute
    , toMonth
    , toSecond
    , toYear
    )

-- elm/core
import String exposing (repeat,length)
import Dict exposing (Dict)

type DateTimeFormat
    = DD_MM_YYYY
    | DD_MM_YYYY_H24_M_S
    | DD_MM_YYYY_H24_M
    | H24_M_S
    | H24_M
    | YYYY_MM_DD_HH_MM_SS
    | YYYY_MM_DD_HH_MM
    | YYYY_MM_DD
    -- | HH_MM_SS -- equals H24_M_S
    | S_D_M_Y_H12_M_S
    | S_D_M_Y_H12_M
    | S_D_M_Y
    | H12_M_S
    | H12_M
    | S_M_D_Y_H12_M_S
    | S_M_D_Y_H12_M
    | S_M_D_Y


all : Dict String DateTimeFormat
all = Dict.fromList
    [ ("DD_MM_YYYY", DD_MM_YYYY)
    , ("DD_MM_YYYY_H24_M_S", DD_MM_YYYY_H24_M_S)
    , ("DD_MM_YYYY_H24_M", DD_MM_YYYY_H24_M)
    , ("H24_M_S", H24_M_S)
    , ("H24_M", H24_M)
    , ("YYYY_MM_DD_HH_MM_SS", YYYY_MM_DD_HH_MM_SS)
    , ("YYYY_MM_DD_HH_MM", YYYY_MM_DD_HH_MM)
    , ("YYYY_MM_DD", YYYY_MM_DD_HH_MM_SS)
    , ("S_D_M_Y_H12_M_S", S_D_M_Y_H12_M_S)
    , ("S_D_M_Y_H12_M", S_D_M_Y_H12_M)
    , ("S_D_M_Y", S_D_M_Y)
    , ("H12_M_S", H12_M_S)
    , ("H12_M", H12_M)
    , ("S_M_D_Y_H12_M_S", S_M_D_Y_H12_M_S)
    , ("S_M_D_Y_H12_M", S_M_D_Y_H12_M)
    , ("S_M_D_Y", S_M_D_Y)
    ]

ex : Int -> Int -> String
ex decimals num =
    let
        t = String.fromInt num
        l = length t
        pl = if l < decimals then decimals - l else 0
        p = repeat pl "0"
    in p ++ t

convert : DateTimeFormat -> Posix -> Zone -> String
convert format time zone =
    let
        d = toDay zone time
        m = case toMonth zone time of
            Jan -> 1
            Feb -> 2
            Mar -> 3
            Apr -> 4
            May -> 5
            Jun -> 6
            Jul -> 7
            Aug -> 8
            Sep -> 9
            Oct -> 10
            Nov -> 11
            Dec -> 12
        y = toYear zone time
        h = toHour zone time
        min = toMinute zone time
        s = toSecond zone time
        h12 = if (modBy 12 h) == 0 then 12 else modBy 12 h
        ampm = if h<12 then "am" else "pm"
    in case format of
        DD_MM_YYYY -> 
            (ex 2 d) ++ "." ++ (ex 2 m) ++ "." ++ (ex 4 y)
        DD_MM_YYYY_H24_M_S -> 
            (ex 2 d) ++ "." ++ (ex 2 m) ++ "." ++ (ex 4 y) ++ " "
            ++ (ex 2 h) ++ ":" ++ (ex 2 min) ++ ":" ++ (ex 2 s)
        DD_MM_YYYY_H24_M -> 
            (ex 2 d) ++ "." ++ (ex 2 m) ++ "." ++ (ex 4 y) ++ " "
            ++ (ex 2 h) ++ ":" ++ (ex 2 min)
        H24_M_S -> 
            (ex 2 h) ++ ":" ++ (ex 2 min) ++ ":" ++ (ex 2 s)
        H24_M -> 
            (ex 2 h) ++ ":" ++ (ex 2 min) 
        YYYY_MM_DD_HH_MM_SS ->
            (ex 4 y) ++ "-" ++ (ex 2 m) ++ "-" ++ (ex 2 d) ++ " "
            ++ (ex 2 h) ++ ":" ++ (ex 2 min) ++ ":" ++ (ex 2 s)
        YYYY_MM_DD_HH_MM ->
            (ex 4 y) ++ "-" ++ (ex 2 m) ++ "-" ++ (ex 2 d) ++ " "
            ++ (ex 2 h) ++ ":" ++ (ex 2 min)
        YYYY_MM_DD ->
            (ex 4 y) ++ "-" ++ (ex 2 m) ++ "-" ++ (ex 2 d)
        S_D_M_Y_H12_M_S ->
            (ex 2 d) ++ "/" ++ (ex 2 m) ++ "/" ++ (ex 4 y) ++ " "
            ++ (ex 2 h12) ++ ":" ++ (ex 2 min) ++ ":" ++ (ex 2 s) ++ " " ++ ampm
        S_D_M_Y_H12_M ->
            (ex 2 d) ++ "/" ++ (ex 2 m) ++ "/" ++ (ex 4 y) ++ " "
            ++ (ex 2 h12) ++ ":" ++ (ex 2 min) ++ " " ++ ampm
        S_D_M_Y ->
            (ex 2 d) ++ "/" ++ (ex 2 m) ++ "/" ++ (ex 4 y)
        H12_M_S ->
            (ex 2 h12) ++ ":" ++ (ex 2 min) ++ ":" ++ (ex 2 s) ++ " " ++ ampm
        H12_M ->
            (ex 2 h12) ++ ":" ++ (ex 2 min) ++ " " ++ ampm
        S_M_D_Y_H12_M_S ->
            (ex 2 m) ++ "/" ++ (ex 2 d) ++ "/" ++ (ex 4 y) ++ " "
            ++ (ex 2 h12) ++ ":" ++ (ex 2 min) ++ ":" ++ (ex 2 s) ++ " " ++ ampm
        S_M_D_Y_H12_M ->
            (ex 2 m) ++ "/" ++ (ex 2 d) ++ "/" ++ (ex 4 y) ++ " "
            ++ (ex 2 h12) ++ ":" ++ (ex 2 min) ++ " " ++ ampm
        S_M_D_Y ->
            (ex 2 m) ++ "/" ++ (ex 2 d) ++ "/" ++ (ex 4 y)