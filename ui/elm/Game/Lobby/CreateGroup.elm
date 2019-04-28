module Game.Lobby.CreateGroup exposing
    ( CreateGroup
    , CreateGroupMsg
    , CreateGroupEvent (..)
    , init 
    , view
    , update
    )
    
import Game.Configuration exposing (..)
import Game.Utils.Language exposing (..)
import Config exposing (..)
import Game.Lobby.ModalWindow exposing (modal)
import Game.Data as Data exposing (..)

import Html exposing (Html,div,text,a,img,input)
import Html.Attributes exposing (class,attribute,href,value)
import Html.Events exposing (onInput,onClick)

type CreateGroup = CreateGroup CreateGroupInfo

type alias CreateGroupInfo =
    { name : String
    }

type CreateGroupMsg
    -- public Methods
    -- private Methods
    = OnClose
    | OnChangeName String
    | OnCreate

type CreateGroupEvent
    = Close
    | Create String

init : CreateGroup
init = CreateGroup
    { name = ""
    }

update : CreateGroupMsg -> CreateGroup -> (CreateGroup, Cmd CreateGroupMsg, List CreateGroupEvent)
update msg (CreateGroup model) = case msg of
    OnClose ->
        ( CreateGroup model
        , Cmd.none
        , [ Close ]
        )
    OnChangeName name ->
        ( CreateGroup { model | name = name }
        , Cmd.none
        , []
        )
    OnCreate ->
        ( CreateGroup model
        , Cmd.none
        , [ Create model.name ]
        )

view : LangLocal -> CreateGroup -> Html CreateGroupMsg
view lang (CreateGroup model) = 
    modal OnClose (getSingle lang ["lobby", "new-group" ]) <|
        div [ class "w-creategroup-box" ] 
            [ text <| getSingle lang ["lobby", "new-group-name"]
            , input
                [ attribute "type" "text"
                , attribute "pattern" ".+"
                , value model.name
                , onInput OnChangeName
                ] []
            , div 
                [ class "w-creategroup-submit"
                , onClick OnCreate
                ]
                [ text <| getSingle lang ["lobby", "on-create-group" ]
                ]
            ]
