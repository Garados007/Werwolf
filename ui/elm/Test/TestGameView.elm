module Test.TestGameView exposing (main)

import ModuleConfig as MC exposing (..)

import Game.UI.GameView as GameView exposing (..)
import Game.Utils.Network as Network exposing (..)
import Game.Types.Request exposing (..)
import Game.Types.Changes exposing (..)
import Game.Configuration exposing (..)
import Game.Utils.Language exposing (..)
import Game.Utils.LangLoader exposing (..)
import Config exposing (..)

import Html exposing (Html, div, node)
import Html.Attributes exposing (style, attribute)
import Navigation exposing (program,Location)
import String exposing (slice)
import Http exposing (decodeUri)

type alias Model =
    { network : Network
    , gameView : GameViewDef EventMsg
    , config : Configuration
    , lang : LangGlobal
    }

type Msg
    = MNetwork NetworkMsg
    | MGameView GameViewMsg
    | MainLang String (Maybe String)
    | ModuleLang String String (Maybe String)
    | None

type EventMsg
    = Register Request
    | Unregister Request
    | Send Request 
    | FetchRuleset String

main : Program Never Model Msg
main = program locChange
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }

locChange : Location -> Msg
locChange loc = None

handleGameView : GameViewEvent -> List EventMsg
handleGameView event = case event of
    GameView.Register req -> [ Register req ]
    GameView.Unregister req -> [ Unregister req ]
    GameView.Send req -> [ Send req ]
    GameView.FetchRuleset set -> [ FetchRuleset set ]

handleEvent : Model -> List EventMsg -> (Model, List (Cmd Msg))
handleEvent = changeWithAll2
    (\model event -> case event of
        Register req ->
            let nm = addRegulary model.network req
            in ({model | network = nm }, Cmd.none)
        Unregister req ->
            let nm = removeRegulary model.network req
            in ({ model | network = nm }, Cmd.none)
        Send req ->
            let ncmd = send model.network req
            in (model, Cmd.map MNetwork ncmd)
        FetchRuleset ruleset ->
            let has = hasGameset model.lang (getCurLang model.lang)
                    ruleset
            in if has
                then (model, Cmd.none)
                else (model
                    , fetchModuleLang ruleset
                        (getCurLang model.lang) ModuleLang
                    )
    )

init : Location -> (Model, Cmd Msg)
init loc = 
    let (group, user) = Maybe.withDefault (3,1) <|
            parse <| loc.search
        (gameView, gcmd, gtasks) = gameViewModule handleGameView (group, user)
        model = Model network gameView empty <|
            newGlobal lang_backup
        (nmodel, eventCmd) = handleEvent model gtasks
    in  (nmodel
        , Cmd.batch <| 
            [ Cmd.map MGameView gcmd
            , Cmd.map MNetwork <| send network <|
                RespGet <| GetConfig
            , fetchUiLang lang_backup MainLang
            , fetchModuleLang "main" lang_backup ModuleLang
            ] ++ eventCmd
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
    , Html.map MGameView <| MC.view model.gameView
    ]

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        MNetwork nmsg -> case nmsg of
            Received changes ->
                let (nm, ncmd) = Network.update nmsg model.network
                    (ng, gcmd, gtasks) = MC.update model.gameView (Manage changes.changes)
                    nmodel = { model | network = nm, gameView = ng }
                    (nnmodel, cmd, ctasks) = List.foldr 
                        (\change (m, list, tasks) -> case change of
                            CConfig str ->
                                let config = case Maybe.map decodeConfig str of
                                        Just conf -> conf
                                        Nothing -> empty
                                    (ng1,gcmd1,gtasks1) = MC.update m.gameView
                                        (GameView.SetConfig config)
                                    
                                in  ({ model 
                                        | config = config
                                        , gameView = ng1 
                                        }
                                    , Cmd.map MGameView gcmd1 :: list
                                    , gtasks1 ++ tasks
                                    )
                            _ -> (m,list,tasks)
                        )
                        (nmodel, [], [])
                        changes.changes
                    (tm, tcmd) = handleEvent nnmodel (gtasks ++ ctasks)
                in 
                    ( tm
                    , Cmd.batch <|
                        [ Cmd.map MNetwork ncmd
                        , Cmd.map MGameView gcmd
                        ] ++ cmd ++ tcmd
                    )
            _ ->
                let
                    (nm, cmd) = Network.update nmsg model.network
                in ({ model | network = nm}, Cmd.map MNetwork cmd)
        MGameView gmsg ->
            let (ng, gcmd, gtasks) = MC.update model.gameView gmsg
                (tm, tcmd) = handleEvent { model | gameView = ng } gtasks
            in (tm, Cmd.batch <| Cmd.map MGameView gcmd :: tcmd )
        MainLang lang content ->
            let nm = { model 
                    | lang = case content of
                        Nothing -> model.lang
                        Just l -> addMainLang model.lang lang l
                    }
                (ng, gcmd, gtasks) = MC.update model.gameView (GameView.SetLang nm.lang)
                (tm, tcmd) = handleEvent { nm | gameView = ng } gtasks
            in (tm, Cmd.batch <| Cmd.map MGameView gcmd :: tcmd )
        ModuleLang mod lang content ->
            let nm = { model 
                    | lang = case content of
                        Nothing -> model.lang
                        Just l -> addSpecialLang model.lang lang mod l
                    }
                (ng, gcmd, gtasks) = MC.update model.gameView (GameView.SetLang nm.lang)
                (tm, tcmd) = handleEvent { nm | gameView = ng } gtasks
            in (tm, Cmd.batch <| Cmd.map MGameView gcmd :: tcmd )
        None -> (model, Cmd.none)

subscriptions : Model -> Sub Msg
subscriptions model = Sub.batch
    [ Sub.map MNetwork <| Network.subscriptions model.network 
    , Sub.map MGameView <| MC.subscriptions model.gameView
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

