module Game.Pages.RoleDescription exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Dict exposing (Dict)

import Game.Utils.Language exposing (LangGlobal, newGlobal, createLocal, addMainLang, addSpecialLang, getSingle, hasGameset)
import Game.Utils.LangLoader exposing (fetchUiLang, fetchModuleLang)
import Config exposing (..)
import Game.Utils.Network exposing (Network, Request, NetworkMsg(..), network, send, update)
import Game.Types.Request exposing (..)
import Game.Types.Response exposing (..)


type alias Model = 
    { lang: LangGlobal
    , network: Network
    , gametypes: List String
    , roles: Dict String (List String)
    }

type Msg
    = MainLang String (Maybe String)


main: Program Never Model Msg
main = program
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }

init: (Model, Cmd Msg)
init =
    ( Model (newGlobal lang_backup) network [] Dict.empty
    , fetchUiLang lang_backup MainLang
    )

view: Model -> Html Msg
view model = 
    let local = createLocal model.lang Nothing
    in  -- text <| getSingle local ["ui", "online"]
        div [] 
            [
                h1 [] [text "Rollen - Wiki"]
            ,   p [] [text "Spieltypen"]
            ,   ul [] 
                   [
                        li [] [a [href "#main"] [text "Main"]]
                   ,    li [] [a [href "#easy"] [text "Easy"]]
                   ] 
            ,   h2 [id "main"] [text "Main"]
            ,   p [] [text "Gewöhnliche Spiele, in denen alle regulären Rollen vorkommen können."]
            ,   h3 [] [text "Dorfbewohner"]
            ,   img [src "https://image.jimcdn.com/app/cms/image/transf/none/path/s804ddaff65002008/image/i482a845d86724cc7/version/1509653870/image.png", alt "Dorfbewohner männlich"] []
            ,   img [src "https://image.jimcdn.com/app/cms/image/transf/none/path/s804ddaff65002008/image/iead242b1b89f56e8/version/1509653890/image.png", alt "Dorfbewohner weiblich"] []
            ,   p [] [text "Gewöhnliche Dorfbewohner ohne Sonderfähigkeiten. Sein Verstand ist seine einzige Waffe bei der Wolfsjagd."]
            ,   h3 [] [text "Werwolf"]
            ,   img [src "https://vignette.wikia.nocookie.net/harrypotter/images/6/6a/Werwolf.png/revision/latest?cb=20130905224334&path-prefix=de", alt "Werwolf"] []
            ,   p [] [text "Gewöhnlicher Werwolf ohne Sonderfähigkeiten. Einigt sich mit seinem Rudel jede Nacht auf ein Fressopfer und versucht tagsüber, nicht aufzufallen."]
            ,   h2 [id "easy"] [text "Easy"]
            ,   p [] [text "Für Anfänger geeignete Runden mit nur wenigen grundlegenden Rollen."]
            ]

update: Msg -> Model -> (Model, Cmd Msg)
update msg model = case msg of
    MainLang lang code -> 
        ( { model | lang = case code of
            Nothing -> model.lang
            Just c -> addMainLang model.lang lang c
          }
        , Cmd.none
        )

subscriptions: Model -> Sub Msg
subscriptions model = Sub.none

