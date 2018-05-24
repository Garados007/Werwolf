module Test.TestGameView exposing (main)

import Game.UI.GameView as GameView exposing (..)
import Game.Utils.Network as Network exposing (..)
import Game.Types.Request exposing (..)
import Game.Types.Changes exposing (..)
import Game.Configuration exposing (..)
import Game.Utils.Language exposing (..)
import Config exposing (..)

import Html exposing (Html, div, node)
import Html.Attributes exposing (style, attribute)
import Navigation exposing (program,Location)
import String exposing (slice)
import Http exposing (decodeUri)
import Task

type alias Model =
    { network : Network
    , gameView : GameView
    , config : Configuration
    , lang : LangGlobal
    }

type Msg
    = MNetwork NetworkMsg
    | MGameView GameViewMsg
    | None

main : Program Never Model Msg
main = program locChange
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }

locChange : Location -> Msg
locChange loc = None

init : Location -> (Model, Cmd Msg)
init loc = 
    let (group, user) = Maybe.withDefault (3,1) <|
            parse <| loc.search
        (gameView, gcmd) = GameView.init group user
    in  (Model network gameView empty <|
            newGlobal lang_backup
        , Cmd.batch
            [ Cmd.map MGameView gcmd
            , Cmd.map MNetwork <| send network <|
                RespGet <| GetConfig
            ]
        )

view : Model -> Html Msg
view model = div 
    [ style 
        [ ("margin-bottom","50px")
        , ("height", "100%")
        , ("width", "100%")
        ]
    ] 
    [ node "link"
        [ attribute "rel" "stylesheet"
        , attribute "property" "stylesheet"
        , attribute "href" "/ui/css/test-game.css"
        ] []
    , node "link"
        [ attribute "rel" "stylesheet"
        , attribute "property" "stylesheet"
        , attribute "href" "https://fonts.googleapis.com/css?family=Kavivanar&amp;subset=latin-ext"
        ] []
    , Html.map MGameView <| GameView.view model.gameView
    ]

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        MNetwork nmsg ->
            case nmsg of
                Received changes ->
                    let
                        (nm, ncmd) = Network.update nmsg model.network
                        (ng, gcmd) = GameView.update (Manage changes.changes) model.gameView
                        nmodel = Model nm ng model.config model.lang
                        (nnmodel, cmd) = List.foldr 
                            (\change (m, list) -> case change of
                                CConfig str ->
                                    let config =
                                            case Maybe.map decodeConfig str of
                                                Just conf -> conf
                                                Nothing -> empty
                                    in  ({ model | config = config }
                                        , (Task.perform MGameView <| Task.succeed <| GameView.SetConfig config) :: list
                                        )
                                _ -> (m,list)
                            )
                            (nmodel, [])
                            changes.changes
                    in 
                        ( nnmodel
                        , Cmd.batch (List.append
                            [ Cmd.map MNetwork ncmd
                            , Cmd.map MGameView gcmd
                            ] cmd )
                        )
                _ ->
                    let
                        (nm, cmd) = Network.update nmsg model.network
                    in ({ model | network = nm}, Cmd.map MNetwork cmd)
        MGameView gmsg ->
            case gmsg of
                RegisterNetwork req ->
                    let
                        nm = addRegulary model.network req
                        (ng, gcmd) = GameView.update gmsg model.gameView
                    in (Model nm ng model.config model.lang, Cmd.map MGameView gcmd)
                UnregisterNetwork req ->
                    let
                        nm = removeRegulary model.network req
                        (ng, gcmd) = GameView.update gmsg model.gameView
                    in (Model nm ng model.config model.lang, Cmd.map MGameView gcmd) 
                SendNetwork req ->
                    let
                        ncmd = send model.network req
                        (ng, gcmd) = GameView.update gmsg model.gameView
                    in 
                        ( { model | gameView = ng }
                        , Cmd.batch
                            [ Cmd.map MNetwork ncmd
                            , Cmd.map MGameView gcmd
                            ]
                        )
                _ -> 
                    let
                        (ng, gcmd) = GameView.update gmsg model.gameView
                    in ({ model | gameView = ng }, Cmd.map MGameView gcmd) 
        None -> (model, Cmd.none)

subscriptions : Model -> Sub Msg
subscriptions model = Sub.batch
    [ Sub.map MNetwork <| Network.subscriptions model.network 
    , Sub.map MGameView <| GameView.subscriptions model.gameView
    ]        

parse : String -> Maybe (Int, Int)
parse text = case slice 0 1 text of
    "" -> Nothing
    "?" -> parse <| String.dropLeft 1 text
    _ ->
        let tiles : List (String, String)
            tiles = String.split "&" text 
                |> List.map (String.split "=")
                |> List.filterMap
                    (\list -> case list of
                        [k,v] -> Just (k,v)
                        _ -> Nothing
                    )
                |> List.map (\(k,v) -> (decodeUri k, decodeUri v))
                |> List.filterMap
                    (\entry -> case entry of
                        (Just k, Just v) -> Just (k,v)
                        _ -> Nothing
                    )
        in case find (\(k,v) -> k == "group") tiles of
            Nothing -> Nothing
            Just (_, group) -> case find (\(k,v) -> k == "user") tiles of
                Nothing -> Nothing
                Just (_, user) -> case (String.toInt group, String.toInt user) of
                    (Ok g, Ok u) -> Just (g, u)
                    _ -> Nothing

find : (a -> Bool) -> List a -> Maybe a
find func list = case list of
    [] -> Nothing
    l :: ls ->
        if func l
        then Just l
        else find func ls

