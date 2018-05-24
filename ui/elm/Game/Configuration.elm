module Game.Configuration exposing
    ( Configuration
    , LangConfiguration
    , empty
    , decodeConfig
    , encodeConfig
    )

import Game.Utils.Language exposing (..)
import Game.Utils.Dates exposing (DateTimeFormat(..))
import Config exposing (..)

import Json.Decode as JD
import Json.Decode.Pipeline exposing (decode,required)
import Json.Encode as JE
import Dict exposing (Dict)
import Result

type alias Configuration =
    { language: String
    , chatDateFormat: DateTimeFormat
    , profileTimeFormat: DateTimeFormat
    , profileDateFormat: DateTimeFormat
    , votingDateFormat: DateTimeFormat
    }

type alias LangConfiguration =
    { conf: Configuration
    , lang: LangLocal
    }

empty : Configuration
empty = Configuration lang_backup DD_MM_YYYY_H24_M_S
    H24_M DD_MM_YYYY DD_MM_YYYY_H24_M_S

decodeConfig : String -> Configuration
decodeConfig code = case JD.decodeString decoder code of
    Ok conf -> conf
    Err err ->
        let d = Debug.log "Configuration:decodeConfig" err
        in empty

encodeConfig : Configuration -> String
encodeConfig config = JE.encode 0 <| JE.object
    [ ("version", JE.int 1)
    , ("language", JE.string config.language)
    , ("chatDateFormat", encodeTime config.chatDateFormat)
    , ("profileTimeFormat", encodeTime config.profileTimeFormat)
    , ("profileDateFormat", encodeTime config.profileDateFormat)
    , ("votingDateFormat", encodeTime config.votingDateFormat)
    ]

decoder : JD.Decoder Configuration
decoder = JD.andThen
    (\version -> case version of
        1 -> decode Configuration
            |> required "language" JD.string
            |> required "chatDateFormat" decodeTime
            |> required "profileTimeFormat" decodeTime
            |> required "profileDateFormat" decodeTime
            |> required "votingDateFormat" decodeTime
        _ -> JD.fail <| "not supported version " ++ (toString version)
    )
    (JD.field "version" JD.int)

decodeTime : JD.Decoder DateTimeFormat
decodeTime = JD.andThen
    (\format -> case Dict.get format Game.Utils.Dates.all of
        Just f -> JD.succeed f
        Nothing -> JD.fail <| "unsupported date format " ++ format
    )
    JD.string

encodeTime : DateTimeFormat -> JE.Value
encodeTime format = Dict.toList Game.Utils.Dates.all
    |> find ((==) format << Tuple.second)
    |> Maybe.map (Tuple.first >> JE.string)
    |> Maybe.withDefault (Debug.crash <|
        "date time format " ++ (toString format) ++
        " is not found in convert list, report this bug at github: "++
        "https://github.com/garados007/Werwolf")

find : (a -> Bool) -> List a -> Maybe a
find f list = case list of
    [] -> Nothing
    l :: ls -> if f l then Just l else find f ls