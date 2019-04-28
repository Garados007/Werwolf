module Game.Lobby.LanguageChanger exposing
    ( LanguageChangerMsg
    , LanguageChangerEvent (..)
    , update
    , view
    )
    
import Game.Utils.Language exposing (..)
import Config exposing (..)
import Game.Lobby.ModalWindow exposing (modal)
import Game.Data as Data exposing (..)

import Html exposing (Html,div,text,a,img,input)
import Html.Attributes exposing (class,attribute,href,value)
import Html.Events exposing (onClick)

type LanguageChangerMsg
    -- public Methods
    -- private Methods
    = OnClose
    | OnChangeLang String

type LanguageChangerEvent
    = Close
    | Change String

update : LanguageChangerMsg -> List LanguageChangerEvent
update msg = case msg of
    OnClose -> [ Close ]
    OnChangeLang key -> [ Change key ]

view : Data -> LangLocal -> Html LanguageChangerMsg
view data lang  = 
    modal OnClose (getSingle lang ["lobby", "language" ]) <|
        div [ class "w-language-box" ] <|
        if data.lang.info == []
        then [ text <| getSingle lang ["lobby", "no-languages" ] ]
        else List.map
            (\ info -> div
                [ class <| (++) "w-language-button" <|
                    if info.short == getCurLangLocal lang
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
            data.lang.info
