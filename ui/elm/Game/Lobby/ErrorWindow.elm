module Game.Lobby.ErrorWindow exposing (viewError,ErrorWindow(..))

import Game.Utils.Language exposing (..)
import Config exposing (..)
import Game.Lobby.ModalWindow exposing (modalNoClose)

import Html exposing (Html,div,text,a,img,input)
import Html.Attributes exposing (class,attribute,href,src)

type ErrorWindow
    = NoError
    | AccountError
    | NetworkError
    | Maintenance

type alias ButtonInfo =
    { header : String
    , imgKey : String
    , descr : String
    , linkUrl : String
    , linkText : String
    }

viewError : LangLocal -> ErrorWindow -> Html msg
viewError lang window = case window of
    NoError -> div [] []
    AccountError -> viewButton lang
        { header = "err-account"
        , imgKey = "wi-account-error"
        , descr = "err-account-descr"
        , linkUrl = uri_host ++ uri_path
        , linkText = "err-account-link"
        }
    NetworkError -> viewButton lang
        { header = "err-network"
        , imgKey = "wi-network-error"
        , descr = "err-network-descr"
        , linkUrl = "javascript:document.location.reload()"
        , linkText = "err-network-link"
        }
    Maintenance -> viewButton lang
        { header = "err-maintenance"
        , imgKey = "wi-maintenance-error"
        , descr = "err-maintenance-descr"
        , linkUrl = uri_host ++ uri_path ++ "ui/maintenance/"
        , linkText = "err-maintenance-link"
        }

viewButton : LangLocal -> ButtonInfo -> Html msg
viewButton lang info = modalNoClose (getSingle lang ["lobby", info.header ])
    <| div [ class "w-error-box" ]
        [ div [ class "w-error-header" ]
            [ div [ class "w-error-image" ]
                [ div [ class info.imgKey ] [] 
                ]
            , div [ class "w-error-text" ]
                [ text <| getSingle lang [ "lobby", info.descr ] 
                ]
            ]
        , a [ class "w-error-button"
            , href info.linkUrl
            ]
            [ text <| getSingle lang [ "lobby", info.linkText ] 
            ]
        ]