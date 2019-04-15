module Game.Utils.Network exposing 
    ( Network
    , Request
    , NetworkMsg
    , newNetwork
    , send
    , update
    , addRegulary
    , removeRegulary
    , subscriptions
    , msgReceived
    , isReceived
    )

import Game.Types.Request exposing 
    ( encodeRequest
    , EncodedRequest
    , Response (..)
    , ResponseMulti (..)
    )
import Game.Types.Response exposing (Response)
import Game.Types.Changes exposing (ChangeConfig,Changes,concentrate)
import Game.Types.DecodeResponse exposing (decodeResponse)

import Http exposing (Error)
import HttpBuilder exposing (withTimeout, withExpect, withCredentials
    , withUrlEncodedBody, withCacheBuster)
import Config exposing (uri_host, uri_path)
import Time
import Result exposing (Result)
import Task exposing (perform,succeed)

type alias Request = Game.Types.Request.Response
type alias Response = Game.Types.Response.Response

type Network
    = Network NetworkInfo 

type NetworkMsg
    = Fetch (Result Error Response)
    | RegSend Time.Posix
    | Received ChangeConfig

type alias NetworkInfo =
    { regular : List Request
    }

msgReceived : ChangeConfig -> NetworkMsg
msgReceived = Received

isReceived : NetworkMsg -> Maybe ChangeConfig
isReceived msg = case msg of 
    Received c -> Just c 
    _ -> Nothing

newNetwork : Network
newNetwork = Network <| NetworkInfo []

send : Network -> Request -> Cmd NetworkMsg
send network request =
    let
        er = encodeRequest request
    in HttpBuilder.post (buildUrl er)
        |> withTimeout 10000
        |> withExpect (Http.expectJson decodeResponse)
        |> withCredentials
        |> withUrlEncodedBody er.vars
        |> withCacheBuster "nocache"
        |> HttpBuilder.send Fetch
        
update : NetworkMsg -> Network -> (Network, Cmd NetworkMsg)
update msg (Network network) =
    case msg of
        RegSend _ ->
            ( Network network
            , send (Network network) <| RespMulti <| Multi network.regular
            )
        Received config -> (Network network, Cmd.none)
        Fetch (Ok resp) ->
            ( Network network
            , perform Received <| succeed <| concentrate resp
            )
        Fetch (Err err) ->
            let
                debug = Debug.log "Network Error" err
            in
                ( Network network
                , perform Received <| succeed <| 
                    ChangeConfig [ Game.Types.Changes.CNetworkError ] False
                )

addRegulary : Network -> Request -> Network
addRegulary (Network network) request =
    if List.member request network.regular
    then Network network
    else Network <| NetworkInfo <| request :: network.regular

removeRegulary : Network -> Request -> Network
removeRegulary (Network network) request =
    Network <| NetworkInfo <| List.filter (\r -> r /= request) network.regular

subscriptions : Network -> Sub NetworkMsg
subscriptions (Network network) =
    if network.regular /= []
    then Time.every 3000 RegSend
    else Sub.none

buildUrl : EncodedRequest -> String
buildUrl er =
    uri_host ++ uri_path ++ "api2/" ++
    er.class ++ "/" ++ er.method ++ "/"