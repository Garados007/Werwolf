module Game.Utils.Dates exposing (DateTimeFormat (..), convert)

import Date exposing (fromTime,day,month,year,Month(..))
import Time exposing (Time,inHours,inMinutes,inSeconds)
import String exposing (repeat,length)

type DateTimeFormat
    = DD_MM_YYYY
    | DD_MM_YYYY_H24_M_S
    | DD_MM_YYYY_H24_M
    | H24_M_S
    | H24_M

ex : Int -> Int -> String
ex decimals num =
    let
        t = toString num
        l = length t
        pl = if l < decimals then decimals - l else 0
        p = repeat pl "0"
    in p ++ t

convert : DateTimeFormat -> Time -> String
convert format time =
    let
        date = fromTime time
        d = day date
        m = case month date of
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
        y = year date
        h = (truncate (inHours time)) % 24
        min = (truncate (inMinutes time)) % 60
        s = (truncate (inSeconds time)) % 60
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