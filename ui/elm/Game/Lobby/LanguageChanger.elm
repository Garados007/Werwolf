module Game.Lobby.LanguageChanger exposing
    ( LanguageChanger
    , LanguageChangerMsg
        ( SetConfig
        , SetLangs
        )
    , LanguageChangerEvent (..)
    , LanguageChangerDef
    , languageChangerModule
    )
    
import ModuleConfig as MC exposing (..)

import Game.Configuration exposing (..)
import Game.Utils.Language exposing (..)
import Config exposing (..)
import Game.Lobby.ModalWindow exposing (modal)
import Game.Utils.LangLoader exposing (LangInfo)

import Html exposing (Html,div,text,a,img,input)
import Html.Attributes exposing (class,attribute,href,value)
import Html.Events exposing (onClick)

type LanguageChanger = LanguageChanger LanguageChangerInfo

type alias LanguageChangerInfo =
    { config : LangConfiguration
    , list : List LangInfo
    }

type LanguageChangerMsg
    -- public Methods
    = SetConfig LangConfiguration
    | SetLangs (List LangInfo)
    -- private Methods
    | OnClose
    | OnChangeLang String

type LanguageChangerEvent
    = Close
    | Change String

type alias LanguageChangerDef a = ModuleConfig LanguageChanger LanguageChangerMsg
    () LanguageChangerEvent a

languageChangerModule : (LanguageChangerEvent -> List a) ->
    (LanguageChangerDef a, Cmd LanguageChangerMsg, List a)
languageChangerModule event = createModule
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }
    event ()

init : () -> (LanguageChanger, Cmd LanguageChangerMsg, List a)
init () =
    ( LanguageChanger
        { config = LangConfiguration empty <|
            createLocal (newGlobal lang_backup) Nothing
        , list = []
        }
    , Cmd.none
    , []
    )

update : LanguageChangerDef a -> LanguageChangerMsg -> LanguageChanger -> (LanguageChanger, Cmd LanguageChangerMsg, List a)
update def msg (LanguageChanger model) = case msg of
    SetConfig config ->
        ( LanguageChanger { model | config = config }
        , Cmd.none
        , []
        )
    SetLangs list ->
        ( LanguageChanger { model | list = list }
        , Cmd.none
        , []
        )
    OnClose ->
        ( LanguageChanger model
        , Cmd.none
        , event def Close
        )
    OnChangeLang key ->
        ( LanguageChanger model
        , Cmd.none
        , event def <| Change key
        )

view : LanguageChanger -> Html LanguageChangerMsg
view (LanguageChanger model) = 
    modal OnClose (getSingle model.config.lang ["lobby", "language" ]) <|
        div [ class "w-language-box" ] <|
        if model.list == []
        then [ text <| getSingle model.config.lang ["lobby", "no-languages" ] ]
        else List.map
            (\ info -> div
                [ class <| (++) "w-language-button" <|
                    if info.short == getCurLangLocal model.config.lang
                    then " selected"
                    else ""
                , onClick <| OnChangeLang info.short
                ]
                [ div [] 
                    [ img
                        [ attribute "src" <| uri_host ++ uri_path ++ 
                            "ui/img/lang/" ++ info.short ++ ".png"
                        ] []
                    ]
                , div [] [ text info.long ]
                , div [] [ text info.en ]
                ]
            )
            model.list

subscriptions : LanguageChanger -> Sub LanguageChangerMsg
subscriptions (LanguageChanger model) =
    Sub.none