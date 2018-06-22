module Game.Lobby.GameMenu exposing
    ( GameMenu
    , GameMenuMsg
        ( SetConfig
        , SetLang
        )
    , GameMenuEvent (..)
    , GameMenuDef
    , gameMenuModule
    )

import ModuleConfig as MC exposing (..)

import Game.Configuration exposing (..)
import Game.Utils.Language exposing (..)
import Config exposing (..)

import Html exposing (Html,div,text,a,img)
import Html.Attributes exposing (class,attribute,href)
import Html.Events exposing (onClick)
import Char

type GameMenu = GameMenu GameMenuInfo

type alias GameMenuInfo =
    { config : LangConfiguration
    , lang : String
    }

type GameMenuMsg
    -- public methods
    = SetConfig LangConfiguration
    | SetLang String
    -- private methods
    | OnEvent GameMenuEvent

type GameMenuEvent
    = CloseMenu
    | NewGameBox
    | JoinGameBox
    | EditGamesBox
    | LanguageBox
    | OptionsBox
    | TutorialBox

type alias GameMenuDef a = ModuleConfig GameMenu GameMenuMsg
    () GameMenuEvent a

gameMenuModule : (GameMenuEvent -> List a) ->
    (GameMenuDef a, Cmd GameMenuMsg, List a)
gameMenuModule event = createModule
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }
    event ()

init : () -> (GameMenu, Cmd GameMenuMsg, List a)
init () =
    ( GameMenu
        { config = LangConfiguration empty <|
            createLocal (newGlobal lang_backup) Nothing
        , lang = lang_backup
        }
    , Cmd.none
    , []
    )

update : GameMenuDef a -> GameMenuMsg -> GameMenu -> (GameMenu, Cmd GameMenuMsg, List a)
update def msg (GameMenu model) = case msg of
    SetConfig config ->
        ( GameMenu { model | config = config }
        , Cmd.none
        , []
        )
    SetLang lang ->
        ( GameMenu { model | lang = lang }
        , Cmd.none
        , []
        )
    OnEvent event ->
        ( GameMenu model
        , Cmd.none
        , MC.event def event
        )

view : GameMenu -> Html GameMenuMsg
view (GameMenu model) = div [ class "w-menu-background" ]
    [ div [ class "w-menu-box" ]
        [ div [ class "w-menu-title" ]
            [ viewTitle model
            ]
        , div [ class "w-menu-content" ]
            [ viewButtons model
            ]
        ]
    ]

viewTitle : GameMenuInfo -> Html GameMenuMsg
viewTitle model = div []
    [ div [ class "w-menu-title-content" ] 
        [ div [ class "w-gameselector-nav", onClick <| OnEvent CloseMenu ] <|
            List.repeat 3 <| div [] []
        , div [] [ text <| menuString model "menu-title" ]
        ]
    ]

menuString : GameMenuInfo -> String -> String
menuString model subkey = getSingle model.config.lang ["lobby", subkey]

viewButtons : GameMenuInfo -> Html GameMenuMsg
viewButtons model = div []
    [ div [ class "w-menu-content-box" ] <| List.singleton <| div []
        [ viewButton (OnEvent NewGameBox) <| menuString model "new-group"
        , viewButton (OnEvent JoinGameBox) <| menuString model "join-group"
        , viewButton (OnEvent EditGamesBox) <| menuString model "manage-groups"
        , viewSplitter
        , viewLink "" <| menuString model "main-screen"
        , viewLink "" <| menuString model "user-info"
        , viewSplitter
        , viewButton (OnEvent TutorialBox) <| menuString model "tutorials"
        , viewSplitter
        , viewImgButton (OnEvent LanguageBox) 
            ("ui/img/lang/" ++ model.lang ++ ".png")
            <| menuString model "language"
        , viewButton (OnEvent OptionsBox) <| menuString model "options"
        , div [ class "w-menu-space" ] []
        , viewCredits
        ]
    ]

viewLink : String -> String -> Html msg
viewLink href label = 
    a   [ class "w-menu-button"
        , attribute "href" <| uri_host ++ uri_path ++ href
        , attribute "target" "_blank"
        ]
        [ text label ]

viewImgButton : msg -> String -> String -> Html msg
viewImgButton msg src label =
    div [ class "w-menu-button image", onClick msg ]
        [ text label
        , img
            [ attribute "src" <| uri_host ++ uri_path ++ src
            ] []
        ]

viewButton : msg -> String -> Html msg
viewButton msg label =
    div [ class "w-menu-button", onClick msg ]
        [ text label ]

viewSplitter : Html msg
viewSplitter = div [ class "w-menu-splitter" ] []

viewCredits : Html msg
viewCredits = div [ class "w-credits" ]
    [ div []
        [ text <| flip String.cons "" <| Char.fromCode 169
        , text <| " 2017 - "
        , text <| toString build_year
        ]
    , div []
        [ text <| "Project from "
        , a [ href "https://github.com/Garados007/Werwolf/"
            , attribute "target" "_blank"
            ]
            [ text "Github" ]
        , text <| " - Version " ++ build_version
        ]
    ]

subscriptions : GameMenu -> Sub GameMenuMsg
subscriptions (GameMenu model) =
    Sub.none