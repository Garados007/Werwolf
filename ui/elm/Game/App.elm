module Game.App exposing (App,Msg,main)

import Game.Utils.Network as Network exposing (Network)
import Game.Data as Data exposing (Data)
import Game.Lobby.GameLobby as GameLobby exposing (GameLobby, GameLobbyMsg, GameLobbyEvent)
import Time exposing (Posix, Zone)
import Browser
import Task
import Html exposing (Html)
import Game.Types.Request exposing (Request)
import DataDiff.Path as Diff exposing (Path, DetectorPath)
import Game.Types.Changes exposing (ChangeConfig)
import DataDiff.Ex as DiffEx

type alias App =
    { network : Network
    , data : Maybe Data
    , model : Maybe GameLobby
    }

type Msg 
    = MsgNetwork Network.NetworkMsg 
    | MsgModel GameLobbyMsg
    | MsgInit (Posix, Zone)
    | MsgNow Posix

type AppTasks 
    = SendRequest Request
    | AddRegular Request 
    | RemoveRegular Request
    | SendMsg Msg
    | HandleChanges ChangeConfig
    | PerformDataChange (Data -> Data)
    | RequireData (Data -> Msg)
    | NoTask

main : Program () App Msg
main = Browser.element 
    { init = always preInit
    , view = view
    , update = \msg model -> updateAll [ SendMsg msg ] model
        |> Tuple.mapSecond Cmd.batch
    , subscriptions = subscriptions
    }

preInit : (App, Cmd Msg)
preInit =
    ( App 
        Network.newNetwork
        Nothing
        Nothing
    , Task.perform MsgInit <|
        Task.map2 Tuple.pair Time.now Time.here
    )

view : App -> Html Msg 
-- view app = case app.data of 
--     Just data -> Html.text 
--         <| (++) "data ready: " 
--         <| String.fromInt
--         <| Time.posixToMillis data.time.now
--     Nothing -> Html.text "loading..."
view app = case Maybe.map2 Tuple.pair app.data app.model of 
    Just (data, model) -> Html.map MsgModel 
        <| GameLobby.view data model
    Nothing -> Html.text "loading..."

paths : App -> DetectorPath Data Msg
paths model = Diff.batch 
    [ case model.model of 
        Just m -> Diff.mapMsg MsgModel <| GameLobby.detector m 
        Nothing -> Diff.noOp

    ]
    -- [ Data.pathTimeData
    --     <| Diff.goPath (Diff.PathString "now") .now
    --     <| Diff.value
    --         [ DiffEx.ChangedEx <| \path old new ->
    --             let d = Debug.log "@data" (path, old, new)
    --             in NoTask
    --         ]
    -- ]

mapGameLobbyEvent : GameLobbyEvent -> AppTasks
mapGameLobbyEvent event = case event of 
    GameLobby.Register req -> AddRegular req 
    GameLobby.Unregister req -> RemoveRegular req 
    GameLobby.Send req -> SendRequest <| Debug.log "Network:sendMsg" req 
    GameLobby.CallMsg msg -> SendMsg <| MsgModel msg 
    GameLobby.ReqData req -> RequireData <| MsgModel << req 
    GameLobby.ModData mod -> PerformDataChange mod

updateAll : List AppTasks -> App -> (App, List (Cmd Msg))
updateAll list model =
    let (nmodel, cmds) = updateTasks list model
        nmsg = updateOnData model nmodel  
    in  if List.isEmpty nmsg
        then (nmodel, cmds)
        else
            let (rmodel, rcds, rtasks) = List.foldl 
                    (\msg (rm, rc, rt) -> updateMsg msg rm 
                        |> \(tm, tc, tt) -> (tm, rc ++ [tc], rt ++ tt)
                    )
                    (nmodel, cmds, [])
                    nmsg
                (fa, fc) = updateAll rtasks rmodel
            in (fa, rcds ++ fc)
    
updateOnData : App -> App -> List Msg
updateOnData old new = Maybe.withDefault [] 
    <| Maybe.map2
        (Diff.execute (paths new) [])
        old.data 
        new.data

updateTasks : List AppTasks -> App -> (App, List (Cmd Msg))
updateTasks list model = case list of 
    [] -> (model, [])
    t :: ts -> 
        let (nmodel, cmd, tasks) = case t of 
                SendRequest r ->
                    ( model
                    , List.singleton
                        <| Cmd.map MsgNetwork
                        <| Network.send model.network r
                    , []
                    )
                AddRegular r -> tripel
                    { model | network = Network.addRegulary model.network r }
                    []
                    []
                RemoveRegular r -> tripel 
                    { model | network = Network.removeRegulary model.network r }
                    []
                    []
                SendMsg msg ->
                    let (ra, rc, rt) = updateMsg msg model
                    in (ra, [ rc ], rt)
                HandleChanges changes -> tripel 
                    { model
                    | data = Maybe.map 
                        (\data -> List.foldl Data.update
                            data 
                            changes.changes
                        )
                        model.data
                    }
                    []
                    []
                PerformDataChange mod -> tripel
                    { model | data = Maybe.map mod model.data }
                    []
                    []
                RequireData req -> tripel
                    model 
                    []
                    <| case model.data of 
                        Just d -> [ SendMsg <| req d ]
                        Nothing -> []
                NoTask -> (model, [], [])
            (tmodel, rcmd) = updateTasks (ts ++ tasks) nmodel
        in (tmodel, cmd ++ rcmd)

updateMsg : Msg -> App -> (App, Cmd Msg, List AppTasks)
updateMsg msg model = case msg of 
    MsgNetwork nmsg ->  
        let (nn, ncmd, res) = Network.update nmsg model.network
        in  ( { model | network = nn }
            , Cmd.map MsgNetwork ncmd
            , List.map HandleChanges res
            )
    MsgInit (posix, zone) -> 
        let (gl, gc, ge) = GameLobby.init
        in tripel
            { model
            | data = Just <| Data.empty posix zone
            , model = Just gl
            }
            (Cmd.map MsgModel gc)
            (List.map mapGameLobbyEvent ge)
    MsgModel nmsg -> case model.model of
        Just m -> 
            let (nn, ncmd, res) = GameLobby.update nmsg m
            in  ( { model | model = Just nn }
                , Cmd.map MsgModel ncmd 
                , List.map mapGameLobbyEvent res
                )
        Nothing -> tripel model Cmd.none []
    MsgNow posix -> tripel
        { model
        | data = Maybe.map
            (\data ->
                { data 
                | time = data.time |> \time ->
                    { time | now = posix }
                }
            )
            model.data
        }
        Cmd.none
        []

subscriptions : App -> Sub Msg 
subscriptions model = Sub.batch
    [ Time.every 3000 MsgNow
    , Sub.map MsgNetwork 
        <| Network.subscriptions model.network
    ]

tripel : a -> b -> c -> (a, b, c)
tripel a b c = (a, b, c)