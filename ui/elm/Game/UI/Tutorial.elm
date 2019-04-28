module Game.UI.Tutorial exposing
    ( Tutorial
    , view
    , viewEmbed
    , viewModal
    , init
    , update
    , TutorialMsg
    )

import Html exposing (Html,div,text,node)
import Html.Attributes exposing (class,attribute,property)
import Html.Events exposing (onClick)
import Html.Lazy exposing (lazy2)

import Game.Configuration exposing (..)
import Game.Utils.Language exposing (..)
import Config exposing (..)
import Game.Lobby.ModalWindow exposing (modal)

import Json.Encode exposing (string)
import Http exposing (Error)
import HttpBuilder exposing (withTimeout, withExpect, withCredentials
    , withUrlEncodedBody)
import Dict exposing (Dict)
import Time
import SvgParser exposing (parse)

maxPage : Int -- constant
maxPage = 7

type Tutorial = Tutorial TutorialInfo

type alias TutorialInfo =
    { page : Int
    , svg : Dict Int String
    }

type TutorialMsg
    = Go Int
    | Fetch Int (Result Error String)

init : (Tutorial, Cmd TutorialMsg)
init = 
    ( Tutorial { page = 0, svg = Dict.empty }
    , fetch 0
    )

divs : Html msg -> Html msg
divs = div [] << List.singleton

viewEmbed : LangLocal -> Tutorial -> Html TutorialMsg
viewEmbed lang = div [ class "w-tutorial-outer" ] 
    << List.singleton << view lang

viewModal : (TutorialMsg -> msg) -> msg -> LangLocal -> Tutorial -> Html msg
viewModal map close lang = modal close 
    (getSingle lang [ "lobby", "tutorials" ]) <<
    Html.map map <<
    div [ class "w-tutorial-modal" ] <<
    List.singleton << view lang

view : LangLocal -> Tutorial -> Html TutorialMsg
view = lazy2 <| \lang (Tutorial model) ->
    div [ class "w-tutorial-box" ]
        [ div
            [ class "w-tutorial-header" 
            -- , property "innerHTML" 
            --     <| string 
            --     <| Debug.log "svg"
            --     <| Maybe.withDefault "" 
            --     <| Dict.get model.page model.svg
            ]
            [ Maybe.withDefault (text "")
                <| Result.toMaybe
                <| parse
                <| Maybe.withDefault ""
                <| Dict.get model.page model.svg

            ]
        , div
            [ class "w-tutorial-info" ]
            [ div
                [ class "w-tutorial-text" ]
                [ text <| getSingle lang 
                    [ "lobby", "tutorial", String.fromInt model.page ]
                ]
            ]
        , div 
            [ class "w-tutorial-navarea" ]
            [ viewNav model.page

            ]
        ]

viewNav : Int -> Html TutorialMsg
viewNav page = div
    [ class "w-tutorial-nav-box" ]
    [ div 
        [ class "w-tutorial-prev" 
        , onClick <| Go <| modBy maxPage <| page + maxPage - 1
        ] []
    , div [ class "w-tutorial-fast" ] <| List.filterMap identity
        [ if page > 1
            then Just <| viewDot "prev2" <| page - 2
            else Nothing
        , if page > 0
            then Just <| viewDot "prev1" <| page - 1
            else Nothing
        , Just <| viewDot "mid" <| page
        , if page < maxPage - 1
            then Just <| viewDot "next1" <| page + 1
            else Nothing
        , if page < maxPage - 2
            then Just <| viewDot "next2" <| page + 2
            else Nothing
        ]
    , div
        [ class "w-tutorial-next"
        , onClick <| Go <| modBy maxPage <| page + 1
        ] []
    ]

viewDot : String -> Int -> Html TutorialMsg
viewDot className page = div
    [ class <| "w-tutorial-dot " ++ className
    , onClick <| Go <| page
    ] []

fetch : Int -> Cmd TutorialMsg
fetch page = HttpBuilder.get
    (uri_host ++ uri_path ++ "ui/img/tutorial/" ++ (String.fromInt page) ++ ".svg")
    |> withTimeout 10000
    |> withExpect Http.expectString
    |> withCredentials
    |> HttpBuilder.send (Fetch page)

update : TutorialMsg -> Tutorial -> (Tutorial, Cmd TutorialMsg)
update msg (Tutorial model) = case msg of
    Go page -> 
        ( Tutorial { model | page = page }
        , Cmd.batch <|
            if Dict.member page model.svg 
            then []
            else [ fetch page ]
        )
    Fetch page (Ok svg) ->
        ( Tutorial { model | svg = Dict.insert page (trimSvg svg) model.svg }
        , Cmd.none
        )
    Fetch page (Err _) ->
        ( Tutorial { model | svg = Dict.insert page "" model.svg }
        , Cmd.none 
        )

trimSvg : String -> String
trimSvg svg =
     case  String.indexes "<svg" svg of
        [] -> svg
        i :: _ -> String.dropLeft i svg
