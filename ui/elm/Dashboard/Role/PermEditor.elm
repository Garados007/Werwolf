module Dashboard.Role.PermEditor exposing (..)

import Html exposing (Html, div, text)
import Html.Attributes as HA exposing (class)
import Html.Events as HE
import Set exposing (Set)
import Dict exposing (Dict)
import Config exposing (uri_host,uri_path)
import List.Extra as LE
import Browser
import Json.Encode as JE

import Dashboard.Environment exposing (..)
import Dashboard.Util.Html exposing (..)

-- main : Platform.Program () Exchange Msg
-- main = Browser.element
--     { init = \() -> Tuple.pair
--         { editor = init
--         , data = Dict.empty
--         , phases = Set.fromList [ "phase1", "phase2", "phase3" ]
--         , chats = Set.fromList [ "chat1", "chat2", "chat3" ]
--         }
--         Cmd.none
--     , view = \model -> div []
--         [ view model
--         , dashboardStylesheet "role-info"
--         ]
--     , update = \msg model -> (update msg model, Cmd.none)
--     , subscriptions = \_ -> Sub.none
--     }

-- local state
type alias PermEditor =
    { mode : ViewMode
    , nativeBox : Bool
    }

-- data
type alias Data = Dict String (Dict String PermissionInfo) -- Phase, chat

type alias Exchange =
    { editor : PermEditor
    , data : Data
    , phases : Set String
    , chats : Set String
    , readonly : Bool 
    }

type ViewMode
    = ThreeCheckBoxes
    | SelectBox
    | OnlyRead
    | OnlyWrite
    | OnlyVisible

type Msg
    = None
    | ChangeViewMode ViewMode
    | ChangeNative Bool
    | SetRead (Maybe String) (Maybe String) Bool
    | SetWrite (Maybe String) (Maybe String) Bool
    | SetVisible (Maybe String) (Maybe String) Bool
    | SetPerm (Maybe String) (Maybe String) PermissionInfo

viewModes : Dict String ViewMode
viewModes = Dict.fromList
    [ Tuple.pair "all check boxes" ThreeCheckBoxes
    , Tuple.pair "select boxes" SelectBox
    , Tuple.pair "only read" OnlyRead
    , Tuple.pair "only write" OnlyWrite
    , Tuple.pair "only visible" OnlyVisible
    ]

viewPerms : Dict String PermissionInfo
viewPerms = Dict.fromList
    [ Tuple.pair "none"
        <| PermissionInfo False False False
    , Tuple.pair "read"
        <| PermissionInfo True False False
    , Tuple.pair "read,visible"
        <| PermissionInfo True False True
    , Tuple.pair "all"
        <| PermissionInfo True True True
    ]

init : PermEditor
init =
    { mode = ThreeCheckBoxes
    , nativeBox = True
    }

view : Exchange -> Html Msg
view exchange = div [ class "perm-editor" ]
    [ div [ class "view-type-selector" ]
        [ Html.span []
            [ text "View mode:" ]
        , Html.select
            [ HE.onInput <| \input -> viewModes
                |> Dict.get input
                |> Maybe.map ChangeViewMode
                |> Maybe.withDefault None
            ]
            <| List.map
                (\(k,v) -> Html.option
                    [ HA.value k
                    , HA.selected <| v == exchange.editor.mode
                    ]
                    [ text k ]
                )
            <| Dict.toList viewModes
        -- , Html.label []
        --     [  Html.input
        --         [ HA.type_ "checkbox"
        --         , HA.checked exchange.editor.nativeBox
        --         , HE.onCheck ChangeNative
        --         ] []
        --     , Html.span []
        --         [ text "use native checkboxes"]
        --     ]
        ]
    , viewData exchange
    ]

viewData : Exchange -> Html Msg
viewData exchange = div [ class "data" ]
    <|  ( div [ class "row" ]
            <|  ( div [ class "header cell" ]
                    <| List.singleton
                    <| viewCell
                        exchange
                        Nothing
                        Nothing
                )
            :: List.map
                (\chat -> div [ class "header cell" ]
                    [ div [ class "chat" ]
                        [ text chat ]
                    , viewCell
                        exchange
                        Nothing
                        (Just chat)
                    ]
                )
                (Set.toList exchange.chats)
        )
    :: List.map
        (\phase -> div [ class "row" ]
            <|  ( div [ class "header cell" ]
                    [ div [ class "phase" ]
                        [ text phase ]
                    , viewCell
                        exchange
                        (Just phase)
                        Nothing
                    ]
                )
            :: List.map
                (\chat -> div [ class "cell" ]
                    <| List.singleton
                    <| viewCell
                        exchange
                        (Just phase)
                        (Just chat)
                )
                (Set.toList exchange.chats)
        )
        (Set.toList exchange.phases)

viewCell : Exchange -> Maybe String -> Maybe String -> Html Msg
viewCell exchange phase chat =
    let perm = searchCurrent exchange phase chat
        tristate = perm.read == Nothing
            || perm.write == Nothing
            || perm.visible == Nothing
        easy = case (perm.read, perm.write, perm.visible) of
            (Just r, Just w, Just v) -> Just <| PermissionInfo r w v
            _ -> Nothing
        valid = Maybe.map 
            (\e -> List.member e 
                <| Dict.values viewPerms
            )
            easy
    in div 
        [ HA.classList
            [ Tuple.pair "perms" True
            , Tuple.pair "invalid" 
                <| valid == Just False
            , Tuple.pair "undefined"
                <| valid == Nothing
            ]
        ]
        <| case exchange.editor.mode of
            ThreeCheckBoxes ->
                [ viewCheckBox
                    exchange.readonly
                    (SetRead phase chat)
                    "Read"
                    exchange.editor.nativeBox
                    perm.read
                , viewCheckBox
                    exchange.readonly
                    (SetWrite phase chat)
                    "Write"
                    exchange.editor.nativeBox
                    perm.write
                , viewCheckBox
                    exchange.readonly
                    (SetVisible phase chat)
                    "Visible"
                    exchange.editor.nativeBox
                    perm.visible
                ]
            OnlyRead ->
                [ viewCheckBox
                    exchange.readonly
                    (SetRead phase chat)
                    "Read"
                    exchange.editor.nativeBox
                    perm.read
                ]
            OnlyWrite ->
                [ viewCheckBox
                    exchange.readonly
                    (SetWrite phase chat)
                    "Write"
                    exchange.editor.nativeBox
                    perm.write
                ]
            OnlyVisible ->
                [ viewCheckBox
                    exchange.readonly
                    (SetVisible phase chat)
                    "Visible"
                    exchange.editor.nativeBox
                    perm.visible
                ]
            SelectBox -> List.singleton
                <|  ( \list -> Html.select
                        [ HE.onInput <| 
                            if exchange.readonly
                            then always None
                            else \input -> list
                                |> List.filter (Tuple.first >> (==) input)
                                |> List.head 
                                |> Maybe.map Tuple.second
                                |> Maybe.withDefault Nothing
                                |> Maybe.map (SetPerm phase chat)
                                |> Maybe.withDefault None
                        , HA.disabled exchange.readonly
                        ]
                        <| List.map
                            (\(n, m) -> Html.option
                                [ HA.value n
                                , HA.selected
                                    <| m == easy
                                ] 
                                [ text n ]
                            )
                        <| list

                    )
                <| (::) ("", Nothing)
                <| List.map (Tuple.mapSecond Just)
                <| Dict.toList viewPerms

viewCheckBox : Bool -> (Bool -> Msg) -> String -> Bool -> Maybe Bool -> Html Msg
viewCheckBox readonly onChange title native checked =
    if native
    then Html.input
        [ HA.type_ "checkbox"
        , HA.title title
        , HA.checked <| checked == Just True
        , HA.property "indeterminate"
            <| JE.bool
            <| checked == Nothing
        , HE.onCheck <| if readonly then always None else onChange
        , HA.disabled readonly
        ] []
    else div
        [ HA.classList
            [ Tuple.pair "checkBox" True
            , Tuple.pair "checked" <| checked == Just True
            , Tuple.pair "unchecked" <| checked == Just False
            ]
        , HA.title title
        , HE.onClick
            <| onChange
            <| not
            <| Maybe.withDefault False
            <| checked
        ]
        [ text <| String.toUpper <| String.left 1 title ]

searchCurrent : Exchange -> Maybe String -> Maybe String
    -> { read : Maybe Bool, write : Maybe Bool, visible : Maybe Bool }
searchCurrent exchange phase chat =
    Maybe.withDefault
        { read = Nothing, write = Nothing, visible = Nothing }
    <|  (\rd -> case rd of
            Just d -> Just d
            Nothing -> List.foldl
                (\(p, c) mo ->
                    let perm = exchange.data
                            |> Dict.get p
                            |> Maybe.andThen (Dict.get c)
                            |> Maybe.withDefault
                                { read = False
                                , write = False
                                , visible = False
                                }
                        modified : a -> Maybe a -> Maybe a
                        modified m1 m2 =
                            if Just m1 == m2
                            then m2
                            else Nothing
                    in case mo of
                        Nothing -> Just
                            { read = Just perm.read
                            , write = Just perm.write
                            , visible = Just perm.visible
                            }
                        Just o -> Just
                            { read = modified perm.read o.read
                            , write = modified perm.write o.write
                            , visible = modified perm.visible o.visible
                            }
                )
                Nothing
                <| cartesianPairs
                    ( case phase of
                        Just p -> [ p ]
                        Nothing -> Set.toList exchange.phases
                    )
                    ( case chat of
                        Just c -> [ c ]
                        Nothing -> Set.toList exchange.chats
                    )
        )
    <| case Maybe.andThen (\k -> Dict.get k exchange.data) phase of
        Nothing -> Nothing
        Just d -> case Maybe.andThen (\k -> Dict.get k d) chat of
            Nothing -> Nothing
            Just p -> Just
                { read = Just p.read
                , write = Just p.write
                , visible = Just p.visible
                }

update : Msg -> Exchange -> Exchange
update msg exchange = case msg of
    None -> exchange
    ChangeViewMode mode ->
        { exchange
        | editor = exchange.editor |> \editor ->
            { editor | mode = mode }
        }
    ChangeNative mode ->
        { exchange
        | editor = exchange.editor |> \editor ->
            { editor | nativeBox = mode }
        }
    SetRead phase chat mode -> updateData
        (\p -> { p | read = mode })
        phase
        chat
        exchange
    SetWrite phase chat mode -> updateData
        (\p -> { p | write = mode })
        phase
        chat
        exchange
    SetVisible phase chat mode -> updateData
        (\p -> { p | visible = mode })
        phase
        chat
        exchange
    SetPerm phase chat perm -> updateData
        (always perm)
        phase
        chat
        exchange

updateData : (PermissionInfo -> PermissionInfo) -> Maybe String -> Maybe String
    -> Exchange -> Exchange
updateData updateFunc phase chat exchange =
    let phases = case phase of
            Just p -> [ p ]
            Nothing -> Set.toList exchange.phases
        chats = case chat of
            Just c -> [ c ]
            Nothing -> Set.toList exchange.chats
        new : PermissionInfo
        new = { read = False, write = False, visible = False }
    in  { exchange
        | data = List.foldl
            (\(p, c) -> Dict.update p
                (\md -> case md of
                    Nothing -> Just
                        <| Dict.singleton c
                        <| updateFunc new
                    Just d -> Just
                        <| Dict.update c
                            ( Maybe.withDefault new
                                >> updateFunc
                                >> Just
                            )
                            d
                )
            )
            exchange.data
            <| cartesianPairs phases chats
        }

cartesianPairs : List a -> List b -> List (a, b)
cartesianPairs a b = List.concatMap
    (\ea -> List.map
        (Tuple.pair ea)
        b
    )
    a