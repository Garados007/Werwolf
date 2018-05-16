module Test.Recursive exposing (main)
import Json.Decode exposing (..)
import Json.Decode.Pipeline exposing (decode, required, optional)
import Html exposing (Html,text)

type alias Box =
    { key : String
    , content : BoxContent
    }

type BoxContent
    = SubBox 
        SubBoxContent
    | Desc 
        String -- the visible text

test : String
test = """{"type":"box","key":"a","box":[{"type":"desc","key":"b","text":"hi"}]}"""

type SubBoxContent = SubBoxContent (List Box)

lazyDecodeBox : Decoder SubBoxContent
lazyDecodeBox = 
    map SubBoxContent (list (lazy (\_ -> decodeBox )))

decodeBox : Decoder Box
decodeBox =
    andThen (map2 Box (field "key" string) << decodeBoxContent )
        (field "type" string)

decodeBoxContent : String -> Decoder BoxContent
decodeBoxContent boxType =
    case boxType of
        "box" ->
            map SubBox
                ( field "box" lazyDecodeBox)
        "desc" ->
            map Desc
                (field "text" string)
        _ -> fail "not supported box type"

main : Html msg
main = text (toString (decodeString decodeBox test))