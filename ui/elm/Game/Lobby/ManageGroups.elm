module Game.Lobby.ManageGroups exposing
    ( ManageGroups
    , ManageGroupsMsg
        ( SetConfig
        , SetGroups
        )
    , ManageGroupsEvent (..)
    , ManageGroupsDef
    , manageGroupsModule
    )
    
import ModuleConfig as MC exposing (..)

import Game.Configuration exposing (..)
import Game.Utils.Language exposing (..)
import Config exposing (..)
import Game.Lobby.ModalWindow exposing (modal)
import Game.Types.Types exposing (..)

import Html exposing (Html,div,text,a,img,input)
import Html.Attributes exposing (class,attribute,href,value)
import Html.Events exposing (onInput,onClick)
import Dict exposing (Dict)

type ManageGroups = ManageGroups ManageGroupsInfo

type alias ManageGroupsInfo =
    { config : LangConfiguration
    , groups : Dict Int Group
    }

type ManageGroupsMsg
    -- public Methods
    = SetConfig LangConfiguration
    | SetGroups (Dict Int Group)
    -- private Methods
    | OnClose

type ManageGroupsEvent
    = Close

type alias ManageGroupsDef a = ModuleConfig ManageGroups ManageGroupsMsg
    () ManageGroupsEvent a

manageGroupsModule : (ManageGroupsEvent -> List a) ->
    (ManageGroupsDef a, Cmd ManageGroupsMsg, List a)
manageGroupsModule event = createModule
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }
    event ()

init : () -> (ManageGroups, Cmd ManageGroupsMsg, List a)
init () =
    ( ManageGroups
        { config = LangConfiguration empty <|
            createLocal (newGlobal lang_backup) Nothing
        , groups = Dict.empty
        }
    , Cmd.none
    , []
    )

update : ManageGroupsDef a -> ManageGroupsMsg -> ManageGroups -> (ManageGroups, Cmd ManageGroupsMsg, List a)
update def msg (ManageGroups model) = case msg of
    SetConfig config ->
        ( ManageGroups { model | config = config }
        , Cmd.none
        , []
        )
    SetGroups groups ->
        ( ManageGroups { model | groups = groups }
        , Cmd.none
        , []
        )
    OnClose ->
        ( ManageGroups model
        , Cmd.none
        , event def Close
        )

view : ManageGroups -> Html ManageGroupsMsg
view (ManageGroups model) = 
    modal OnClose (getSingle model.config.lang ["lobby", "manage-groups" ]) <|
        div [ class "w-managegroup-box" ] 
            [ text <| toString model.groups
            ]

subscriptions : ManageGroups -> Sub ManageGroupsMsg
subscriptions (ManageGroups model) =
    Sub.none