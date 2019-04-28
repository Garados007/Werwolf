module Game.Lobby.GameMenu exposing
    ( GameMenuMsg
    , GameMenuEvent (..)
    , view
    , update
    )

import Game.Utils.Language exposing (..)
import Config exposing (lang_backup, uri_host, uri_path, build_year, build_version)

import Html exposing (Html,div,text,a,img)
import Html.Attributes exposing (class,attribute,href)
import Html.Events exposing (onClick)
import Char

type GameMenuMsg
    -- public methods
    -- private methods
    = OnEvent GameMenuEvent

type GameMenuEvent
    = CloseMenu
    | NewGameBox
    | JoinGameBox
    | EditGamesBox
    | LanguageBox
    | OptionsBox
    | TutorialBox

update : GameMenuMsg -> List GameMenuEvent
update msg = case msg of
    OnEvent event -> [ event ]

view : LangLocal -> Html GameMenuMsg
view lang = div [ class "w-menu-background" ]
    [ div [ class "w-menu-box" ]
        [ div [ class "w-menu-title" ]
            [ viewTitle lang
            ]
        , div [ class "w-menu-content" ]
            [ viewButtons lang
            ]
        ]
    ]

viewTitle : LangLocal -> Html GameMenuMsg
viewTitle lang = div []
    [ div [ class "w-menu-title-content" ] 
        [ div [ class "w-gameselector-nav", onClick <| OnEvent CloseMenu ] <|
            List.repeat 3 <| div [] []
        , div [] [ text <| menuString lang "menu-title" ]
        ]
    ]

menuString : LangLocal -> String -> String
menuString lang subkey = getSingle lang ["lobby", subkey]

viewButtons : LangLocal -> Html GameMenuMsg
viewButtons lang = div []
    [ div [ class "w-menu-content-box" ] <| List.singleton <| div []
        [ viewButton (OnEvent NewGameBox) <| menuString lang "new-group"
        , viewButton (OnEvent JoinGameBox) <| menuString lang "join-group"
        , viewButton (OnEvent EditGamesBox) <| menuString lang "manage-groups"
        , viewSplitter
        , viewLink "" <| menuString lang "main-screen"
        , viewLink "" <| menuString lang "user-info"
        , viewSplitter
        , viewButton (OnEvent TutorialBox) <| menuString lang "tutorials"
        , viewLink "ui/roles/" <| menuString lang "role-wiki"
        , viewSplitter
        , viewImgButton (OnEvent LanguageBox) 
            ("ui/img/lang/" ++ (getCurLangLocal lang) ++ ".png")
            <| menuString lang "language"
        , viewButton (OnEvent OptionsBox) <| menuString lang "options"
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
        [ text <| String.fromChar <| Char.fromCode 169
        , text <| " 2017 - "
        , text <| String.fromInt build_year
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
