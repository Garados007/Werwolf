module ModuleConfig exposing
    ( ModuleConfig
    , ModuleConfigCreateOption
    , createModule
    , view
    , update
    , subscriptions
    , event
    -- convient functions for tests
    , programInit
    , programUpdate
    )

import Html exposing (Html)
import Html.Lazy exposing (lazy)

type ModuleConfig model msg createOptions eventMethod event
    = ModuleConfig (Local model msg createOptions eventMethod event)

type alias ModuleConfigCreateOption model msg createOptions eventMethod event =
    { init : createOptions -> (model, Cmd msg, List event)
    , view : model -> Html msg
    , update : ModuleConfig model msg createOptions eventMethod event -> 
        msg -> model -> (model, Cmd msg, List event)
    , subscriptions : model -> Sub msg
    }

type alias Local model msg createOptions eventMethod event =
    { config : ModuleConfigCreateOption model msg createOptions eventMethod event
    , model : model
    , events : eventMethod -> List event
    }

createModule : ModuleConfigCreateOption model msg createOptions eventMethod event -> 
    (eventMethod -> List event) -> createOptions -> 
    (ModuleConfig model msg createOptions eventMethod event, Cmd msg, List event)
createModule config events options =
    let
        (m, c, l) = config.init options
    in (ModuleConfig <|
        { config = config
        , model = m
        , events = events
        }
        , c
        , l
    )

view : ModuleConfig model msg createOptions eventMethod event -> Html msg
view (ModuleConfig module_) =
    lazy module_.config.view <| module_.model

update : ModuleConfig model msg createOptions eventMethod event -> 
    msg -> (ModuleConfig model msg createOptions eventMethod event, Cmd msg, List event)
update (ModuleConfig module_) msg =
    let
        (nm, cmd, el) = module_.config.update (ModuleConfig module_) msg module_.model
        mod = { module_ | model = nm }
    in (ModuleConfig mod, cmd, el)

subscriptions : ModuleConfig model msg createOptions eventMethod event -> Sub msg
subscriptions (ModuleConfig module_) =
    module_.config.subscriptions module_.model

event : ModuleConfig model msg createOptions eventMethod event -> 
    eventMethod -> List event
event (ModuleConfig module_) method = module_.events method

programInit : (createOptions -> (model, Cmd msg, List event)) -> createOptions -> (model, Cmd msg)
programInit func default = 
    let
        (m,c,e) = func default
    in (m,c)

programUpdate : (ModuleConfig model msg createOptions eventMethod event -> 
        msg -> model -> (model, Cmd msg, List event)) -> msg -> model -> (model, Cmd msg)
programUpdate func msg model =
    let
        (m, c, e) = func 
            ( ModuleConfig <|
                Local
                    ( ModuleConfigCreateOption
                        (\c -> (model, Cmd.none, []))
                        (\m -> Html.div [] [])
                        func
                        (\m -> Sub.none)
                    )
                    model
                    (\e -> [])
            )
            msg
            model
    in (m, c)

