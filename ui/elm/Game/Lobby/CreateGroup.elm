module Game.Lobby.CreateGroup exposing
    ( CreateGroup
    , CreateGroupMsg
    , CreateGroupEvent (..)
    , CreateGroupDef
    , createGroupModule
    , msgSetConfig
    )
    
import ModuleConfig as MC exposing (..)

import Game.Configuration exposing (..)
import Game.Utils.Language exposing (..)
import Config exposing (..)
import Game.Lobby.ModalWindow exposing (modal)

import Html exposing (Html,div,text,a,img,input)
import Html.Attributes exposing (class,attribute,href,value)
import Html.Events exposing (onInput,onClick)

type CreateGroup = CreateGroup CreateGroupInfo

type alias CreateGroupInfo =
    { config : LangConfiguration
    , name : String
    }

type CreateGroupMsg
    -- public Methods
    = SetConfig LangConfiguration
    -- private Methods
    | OnClose
    | OnChangeName String
    | OnCreate

msgSetConfig : LangConfiguration -> CreateGroupMsg
msgSetConfig = SetConfig

type CreateGroupEvent
    = Close
    | Create String

type alias CreateGroupDef a = ModuleConfig CreateGroup CreateGroupMsg
    () CreateGroupEvent a

createGroupModule : (CreateGroupEvent -> List a) ->
    (CreateGroupDef a, Cmd CreateGroupMsg, List a)
createGroupModule event = createModule
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }
    event ()

init : () -> (CreateGroup, Cmd CreateGroupMsg, List a)
init () =
    ( CreateGroup
        { config = LangConfiguration empty <|
            createLocal (newGlobal lang_backup) Nothing
        , name = ""
        }
    , Cmd.none
    , []
    )

update : CreateGroupDef a -> CreateGroupMsg -> CreateGroup -> (CreateGroup, Cmd CreateGroupMsg, List a)
update def msg (CreateGroup model) = case msg of
    SetConfig config ->
        ( CreateGroup { model | config = config }
        , Cmd.none
        , []
        )
    OnClose ->
        ( CreateGroup model
        , Cmd.none
        , event def Close
        )
    OnChangeName name ->
        ( CreateGroup { model | name = name }
        , Cmd.none
        , []
        )
    OnCreate ->
        ( CreateGroup model
        , Cmd.none
        , event def <| Create model.name
        )

view : CreateGroup -> Html CreateGroupMsg
view (CreateGroup model) = 
    modal OnClose (getSingle model.config.lang ["lobby", "new-group" ]) <|
        div [ class "w-creategroup-box" ] 
            [ text <| getSingle model.config.lang ["lobby", "new-group-name"]
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
                [ text <| getSingle model.config.lang ["lobby", "on-create-group" ]
                ]
            ]

subscriptions : CreateGroup -> Sub CreateGroupMsg
subscriptions (CreateGroup model) =
    Sub.none