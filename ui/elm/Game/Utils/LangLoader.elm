module Game.Utils.LangLoader exposing 
    ( fetchUiLang
    , fetchModuleLang
    )

import Http exposing (Error)
import HttpBuilder exposing (withTimeout, withExpect, withCredentials
    , withUrlEncodedBody, withCacheBuster)
import Config exposing (uri_host, uri_path)
import Result exposing (Result)
import Time

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

getUrl : String -> String -> String
getUrl lang dir =
    uri_host ++ uri_path ++ "lang2/" ++ dir ++ "/" ++
    lang ++ ".json"