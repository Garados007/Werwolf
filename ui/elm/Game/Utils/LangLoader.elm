module Game.Utils.LangLoader exposing 
    ( fetchUiLang
    , fetchModuleLang
    , LangInfo
    , fetchLangList
    )

import Http exposing (Error)
import HttpBuilder exposing (withTimeout, withExpect, withCredentials
    , withUrlEncodedBody, withCacheBuster)
import Config exposing (uri_host, uri_path)
import Result exposing (Result)
import Time
import Json.Decode exposing (Decoder,list,string)
import Json.Decode.Pipeline exposing (decode,required)

type alias LangInfo =
    { short : String -- short key
    , long : String  -- language name in given language
    , en : String    -- language name in english
    }

fetchUiLang : String -> (String -> Maybe String -> msg) -> Cmd msg
fetchUiLang lang msgFunc =
    HttpBuilder.get (getUrl lang "ui")
        |> withTimeout (10 * Time.second)
        |> withExpect Http.expectString
        |> withCredentials
        |> HttpBuilder.send
            (\result -> case result of
                Ok l -> msgFunc lang (Just l)
                Err e ->
                    let d = Debug.log "LangLoader:fetchUiLang" (lang,e)
                    in msgFunc lang Nothing
            )

fetchModuleLang : String -> String -> (String -> String -> Maybe String -> msg) -> Cmd msg
fetchModuleLang module_ lang msgFunc =
    HttpBuilder.get (getUrl lang <| "modules/" ++ module_)
        |> withTimeout (10 * Time.second)
        |> withExpect Http.expectString
        |> withCredentials
        |> HttpBuilder.send
            (\result -> case result of
                Ok l -> msgFunc module_ lang (Just l)
                Err e ->
                    let d = Debug.log "LangLoader:fetchModuleLang" (module_,lang,e)
                    in msgFunc module_ lang Nothing
            )

fetchLangList : (List LangInfo -> msg) -> Cmd msg
fetchLangList msg =
    HttpBuilder.get (uri_host ++ uri_path ++ "lang2/langlist.json")
        |> withTimeout (10 * Time.second)
        |> withExpect (Http.expectJson <| list langInfoDecoder)
        |> withCredentials
        |> HttpBuilder.send
            (\result -> case result of
                Ok l -> msg l
                Err e ->
                    let d = Debug.log "LangLoader:fetchLangList" e
                    in msg []
            )

langInfoDecoder : Decoder LangInfo
langInfoDecoder =
    decode LangInfo
        |> required "short" string
        |> required "long" string
        |> required "en" string

getUrl : String -> String -> String
getUrl lang dir =
    uri_host ++ uri_path ++ "lang2/" ++ dir ++ "/" ++
    lang ++ ".json"