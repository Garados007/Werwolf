module Game.Utils.Network exposing 
    ( Network
    , Request
    , NetworkMsg (Received)
    , network
    , send
    , update
    , addRegulary
    , removeRegulary
    , subscriptions
    )

import Game.Types.Request exposing (encodeRequest,EncodedRequest)
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

type Network
    = Network NetworkInfo 

type NetworkMsg
    = Fetch (Result Error Response)
    | RegSend Time.Time
    | Received ChangeConfig

type alias NetworkInfo =
    { regular : List Request
    }

network : Network
network = Network <| NetworkInfo []

send : Network -> Request -> Cmd NetworkMsg
send network request =
    let
        er = encodeRequest request
    in HttpBuilder.post (buildUrl er)
        |> withTimeout (10 * Time.second)
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
            , Cmd.batch <| List.map (send <| Network network) network.regular
            )
        Received config -> (Network network, Cmd.none)
        Fetch (Ok resp) ->
            ( Network network
            , perform Received <| succeed <| concentrate resp
            )
        Fetch (Err _) ->
            ( Network network
            , perform Received <| succeed <| 
                ChangeConfig [ Game.Types.Changes.CNetworkError ] False
            )

addRegulary : Network -> Request -> Network
addRegulary (Network network) request =
    Network <| NetworkInfo <| request :: network.regular

removeRegulary : Network -> Request -> Network
removeRegulary (Network network) request =
    Network <| NetworkInfo <| List.filter (\r -> r /= request) network.regular

subscriptions : Network -> Sub NetworkMsg
subscriptions (Network network) =
    Time.every (3 * Time.second) RegSend

buildUrl : EncodedRequest -> String
buildUrl er =
    uri_host ++ uri_path ++ "api2/" ++
    er.class ++ "/" ++ er.method ++ "/"