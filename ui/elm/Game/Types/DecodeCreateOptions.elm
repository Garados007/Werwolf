module Game.Types.DecodeCreateOptions exposing
    (decodeCreateOptions)

import Json.Decode exposing (..)
import Json.Decode.Pipeline exposing (decode, required, optional)
import Game.Types.CreateOptions exposing (..)

decodeCreateOptions : Decoder CreateOptions
decodeCreateOptions =
    decode CreateOptions
        |> required "chapter" string
        |> required "box" (list decodeBox)

decodeBox : Decoder Box
decodeBox =
    andThen 
        (map3 Box
            (field "key" string)
            (field "title" string)
            << decodeBoxContent
        )
        (field "type" string)

lazyDecodeBox : Decoder SubBoxContent
lazyDecodeBox = 
    map SubBoxContent (list (lazy (\_ -> decodeBox )))

decodeBoxContent : String -> Decoder BoxContent
decodeBoxContent boxType =
    case boxType of
        "box" ->
            decode SubBox
                |> required "box" lazyDecodeBox
        "desc" ->
            decode Desc
                |> required "text" string
        "num" ->
            decode Num
                |> optional "min" float -4294967296
                |> optional "max" float  4294967295
                |> optional "digits" int 0
                |> optional "default" float 0
        "text" ->
            decode Text
                |> optional "default" string ""
                |> optional "regex" string ".*"
        "check" ->
            decode Check
                |> optional "default" bool False
        "list" ->
            decode OptList
                |> required "options"
                    (list (decodeTuple2 string))
        _ -> fail "not supported box type"
        

decodeTuple2 : Decoder a -> Decoder (a,a)
decodeTuple2 decoder=
    map2 
        (\a b -> (a,b))
        (index 0 decoder)
        (index 1 decoder)