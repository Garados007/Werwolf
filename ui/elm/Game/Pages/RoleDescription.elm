module Game.Pages.RoleDescription exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Dict exposing (Dict)

import Game.Utils.Language exposing (LangGlobal, LangLocal, newGlobal, createLocal, addMainLang, addSpecialLang, getSingle, hasGameset, updateCurrentLang)
import Game.Utils.LangLoader exposing (fetchPageLang, fetchModuleLang, LangInfo, fetchLangList)
import Config exposing (..)
import Game.Utils.Network as Network exposing (Network, NetworkMsg(..), newNetwork, send, update)
import Game.Types.Request exposing (..)
import Game.Types.Changes exposing (Changes(..))
import Browser

st : a -> List a
st = List.singleton

-- deprecated since elm 0.18
-- (<~|) : (List a -> b) -> a -> b
-- (<~|) f v = f [ v ]
-- infixr 0 <~|

type alias Model = 
    { lang: LangGlobal
    , network: Network
    , gametypes: List String
    , roles: Dict String (List String)
    , langs: List LangInfo
    }

type Msg
    = MainLang String (Maybe String)
    | ModuleLang String String (Maybe String)
    | LangList (List LangInfo)
    | ChangeLang String
    | MNetwork NetworkMsg

main: Program () Model Msg
main = Browser.element
    { init = always init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }

init: (Model, Cmd Msg)
init =
    ( Model (newGlobal lang_backup) newNetwork [] Dict.empty []
    , Cmd.batch 
        [ fetchPageLang "roles" lang_backup MainLang
        , Cmd.map MNetwork <| send newNetwork <|
            ReqInfo <| InstalledGameTypes
        , fetchLangList LangList
        ]
    )

view: Model -> Html Msg
view model = 
    let local = createLocal model.lang Nothing
    in  div []
        [ viewPage model local
        , viewSidebar model local
        ]

viewPage : Model -> LangLocal -> Html Msg 
viewPage model local =
    div [ class "page" ] <|
        stylesheet (absUrl "ui/css/page/roles.css") ::
        h1 [] [ text <| getSingle local ["wiki", "title"] ] ::
        div [ class "header" ] [ text <| getSingle local [ "wiki", "header" ] ] ::
        viewIndex model local ++
        (List.concatMap (viewModule model) model.gametypes)

viewIndex : Model -> LangLocal -> List (Html Msg)
viewIndex model local =
    [ div [ class "toc" ]
        [ h2 [ class "toctitle" ]
            [ text <| getSingle local ["wiki", "index"] ]
        , ul []  <| List.indexedMap
            (\ind1 type_ -> 
                let spec = createLocal model.lang <| Just type_
                in li []
                    [ a [ href <| "#" ++ type_ ] 
                        [ span [ class "index" ] 
                            [ text <| (String.fromInt <| ind1 + 1) ++ ". " ]
                        , span []
                            [ text <| getSingle spec ["module-name"] 
                            ]
                        ]
                    , ul [] <| List.indexedMap
                        (\ind2 role -> li [] 
                            [ a [ href <| "#" ++ type_ ++ "-" ++ role ] 
                                [ span [ class "index" ]
                                    [ text <| 
                                        (String.fromInt <| ind1 + 1) ++
                                        "." ++
                                        (String.fromInt <| ind2 + 1) ++
                                        ". "
                                    ]
                                , span []
                                    [ text <| getSingle spec [ "roles", role] 
                                    ]
                                ]
                            ]
                        ) <|
                        Maybe.withDefault [] <|
                        Dict.get type_ model.roles
                    ]
            )
            model.gametypes
        ]
    ]

viewModule : Model -> String -> List (Html Msg)
viewModule model module_ =
    let lang = createLocal model.lang <| Just module_
    in  [ h2 [ id module_ ]
            [ text <| getSingle lang [ "module-name" ] ]
        , div [ class "module-info"]
            [ text <| getSingle lang [ "module-info" ] ]
        , div [ class "role-grid" ] <| List.map
            (\role -> div [ class "role-row", id <| module_ ++ "-" ++ role ]
                [ div [] <| List.singleton <| img
                    [ src <| absUrl <|
                        "ui/img/roles/" ++ module_ ++
                        "/" ++ role ++ ".svg"
                    ] []
                , div [] 
                    [ h3 [] [ text <| getSingle lang ["roles", role] ]
                    , text <| getSingle lang [ "role-wiki", role ] 
                    ]
                ]
            ) <|
            Maybe.withDefault [] <|
            Dict.get module_ model.roles
        ]

viewSidebar : Model -> LangLocal -> Html Msg
viewSidebar model local = 
    let lia : String -> List String -> Html Msg
        lia = \url lkey ->
            li [] 
                <| st
                <| a [ href <| absUrl url ] 
                <| st
                <| text 
                <| getSingle local lkey
    in div [ class "sidebar" ]
        [ div [ class "sidebar-block" ] <| st <| ul []
            [ lia "" [ "nav", "home" ]
            , lia "ui/game/" [ "nav", "game" ] 
            ]
        , div [ class "sidebar-block"]
            [ h3 []
                [ text <| getSingle local [ "wiki", "wikis" ]]
            , ul []
                [ lia "ui/roles/" [ "wiki", "title" ]
                ]
            ]
        , div [ class "sidebar-block"]
            [ h3 []
                [ text <| getSingle local [ "wiki", "other-lang" ]]
            , ul [] <| List.map
                (\l -> li [] 
                    <| st 
                    <| a [ onClick <| ChangeLang l.short ] 
                    <| st 
                    <| text 
                    <| l.long
                )
                model.langs
            ]
        ]

stylesheet : String -> Html msg
stylesheet url = node "link"
    [ attribute "rel" "stylesheet"
    , attribute "property" "stylesheet"
    , attribute "href" url
    ] []

absUrl : String -> String
absUrl url = uri_host ++ uri_path ++ url

update: Msg -> Model -> (Model, Cmd Msg)
update msg model = case msg of
    MainLang lang code -> 
        ( { model | lang = case code of
            Nothing -> model.lang
            Just c -> addMainLang model.lang lang c
          }
        , Cmd.none
        )
    ModuleLang module_ lang code ->
        ( { model | lang = case code of
            Nothing -> model.lang
            Just c -> addSpecialLang model.lang lang module_ c
          }
        , Cmd.none
        )
    LangList list ->
        ({ model | langs = list }, Cmd.none)
    ChangeLang lang ->
        ( { model | lang = updateCurrentLang model.lang lang }
        , Cmd.none 
        )
    MNetwork smsg -> 
        let (nn, ncmd, changed) = Network.update smsg model.network
            (nm, ucmd) = List.foldl
                updateChanges
                ({ model | network = nn }, [])
                <| List.concatMap .changes changed
        in  ( nm
            , Cmd.batch 
                <| Cmd.map MNetwork ncmd
                :: ucmd
            )

updateChanges : Changes -> (Model, List (Cmd Msg)) -> (Model, List (Cmd Msg))
updateChanges change (model, cmd) = case change of
    CInstalledGameTypes types ->
        ( { model | gametypes = types }
        ,   ( Cmd.map MNetwork <| send model.network <|
                ReqMulti <| Multi <| List.map
                (ReqInfo << Rolesets)
                types
            ) :: 
            (List.map 
                (\t -> fetchModuleLang t lang_backup ModuleLang
                )
                types
            ) ++
            cmd
        )
    CRolesets type_ roles ->
        ( { model | roles = Dict.insert type_ roles model.roles }
        , cmd
        )
    _ -> (model, cmd)

subscriptions: Model -> Sub Msg
subscriptions model = Sub.none

