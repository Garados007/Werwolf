module Dashboard.Editor.View exposing (..)

import Dashboard.Editor.Logic exposing (..)
import Html exposing (Html, text, div)
import Html.Attributes as HA exposing (class)
import Html.Events as HE exposing (onClick)

import Dict exposing (Dict)
import Set exposing (Set)
import List.Extra as LE


viewNewEntryBox 
    : (CodeElement -> msg)
    -> (String -> msg)
    -> (Maybe CodeCategory -> msg)
    -> (Maybe String -> msg)
    -> VarEnvironment
    -> String 
    -> Maybe CodeCategory
    -> Maybe String 
    -> TypeInfo
    -> Html msg 
viewNewEntryBox onCreateElement onFilter onCategory onDetails vars filter category details type_ = div 
    [ class "new-entry-box"
    ]
    [ div [ class "container" ]
        [ div [ class "header" ]
            [ div [ class "filter-icons" ]
                <| List.map
                    (\(f,c,t) -> div
                        [ class <| "filter-icon " ++ c ++
                            (if f == category then " active" else "")
                        , onClick <| onCategory f
                        , HA.title t
                        ] []
                    )
                    [ (Nothing, "all", "All Elements")
                    , (Just CCCalculation, "calc", "Calculations")
                    , (Just CCVariables, "vars", "Variables")
                    , (Just CCBranches, "branch", "Branches")
                    , (Just CCUtility, "util", "Utilities")
                    ]
            , div [ class "filter-text" ]
                [ Html.input
                    [ HA.type_ "text"
                    , HA.value filter
                    , HE.onInput onFilter
                    , HA.placeholder "Enter a name to filter"
                    , HA.id "new-entry-box-search-box"
                    ] []
                ]
            ]
        , div [ class "elements" ]
            <| List.map
                (\(e,i) -> div 
                    [ class <| (++) "element "
                        <| case i.category of 
                            CCCalculation -> "calc"
                            CCVariables -> "vars"
                            CCBranches -> "branch"
                            CCUtility -> "util"
                    ]
                    [ div 
                        [ class "create-button" 
                        , HE.onClick <| onCreateElement e.init
                        , HE.onMouseEnter <| onDetails <| Just e.key
                        ]
                        [ div [ class "title" ]
                            [ text e.name ]
                        , div [ class "desc" ]
                            [ text e.desc ]
                        , div [ class "type" ]
                            [ text <| typeString e.type_ ]
                        ]
                    , div 
                        [ class <| (++) "preview-button" 
                            <| if Just e.key == details then " active" else ""
                        , HE.onClick <| onDetails <| 
                            if Just e.key == details 
                            then Nothing
                            else Just e.key
                        ]
                        [ div [] [ text "(i)" ]
                        ]
                    ]
                )
            <| List.filter 
                ( case category of 
                    Nothing -> always True 
                    Just c -> Tuple.second >> .category >> (==) c
                )
            <| List.map (\e -> Tuple.pair e <| getEditInfo vars e.init)
            <| List.filter 
                (\e -> 
                    ( String.contains 
                        (String.toLower filter) 
                        (String.toLower e.name) 
                    || String.contains 
                        (String.toLower filter)
                        (String.toLower e.desc)
                    )
                    && canAdjustType e.type_ type_
                )
            <| Dict.values codeElements
        ]
    , case Maybe.andThen (\d -> Dict.get d codeElements) details of 
        Nothing -> text ""
        Just det -> div [ class "details" ]
            [ viewCodePreview vars det.init
            ]
    ]

viewCodePreview : VarEnvironment -> CodeElement -> Html msg 
viewCodePreview vars element =
    let info = getEditInfo vars element
        details = Dict.get info.key codeElements
        viewEntry : CodeEditEntry -> Html msg 
        viewEntry entry = case entry of 
            CEEValue vname val -> div
                [ class "item value" ]
                [ div [ class "placeholder"] 
                    [ text <| "Value: " ++ vname 
                    ]
                , div [ class "type" ]
                    [ text <| typeString val.desiredType ]
                ]
            CEEParameter val typ -> div
                [ class "item param" ]
                [ div [ class "placeholder" ]
                    [ text "Parameter" ]
                , div [ class "type" ]
                    [ text <| typeString typ ]
                ]
            CEEBlock bname _ -> div 
                [ class "item block" ]
                [ div [ class "placeholder" ]
                    [ text <| "CodeBlock: " ++ bname
                    ]
                ]
            CEEMath _ -> div 
                [ class "item op" ]
                [ div [ class "placeholder" ]
                    [ text "Operator" ]
                ]
            CEECompare _ -> div 
                [ class "item op" ]
                [ div [ class "placeholder" ]
                    [ text "Operator" ]
                ]
            CEEBool _ -> div 
                [ class "item op" ]
                [ div [ class "placeholder" ]
                    [ text "Operator" ]
                ]
            CEEList _ list -> div [ class "item list" ]
                <|  [ div [ class "placeholder list" ]
                        [ text "List of" ]
                    ]
                ++ List.map viewEntry list
    in div 
        [ class <| (++) "code-preview " 
            <| case info.category of 
                CCCalculation -> "calc"
                CCVariables -> "vars"
                CCBranches -> "branch"
                CCUtility -> "util"
        ]
        [ div [ class "header" ]
            [ div [ class "command-name" ]
                [ text <| Maybe.withDefault info.key
                    <| Maybe.map .name details
                ]
            , div [ class "output-type" ]
                [ text <| typeString
                    <| getTypeOf element 
                    <| VarEnvironment Dict.empty Set.empty
                        Set.empty Set.empty Set.empty
                ]
            ]
        , div [ class "setup-container" ]
            <| List.map viewEntry
            <| info.entrys
        ]

type alias VCEEvents msg = 
    { onChange : List Int -> CodeEditEntry -> msg 
    , onViewError : List Int -> Bool -> msg 
    , onAddBlock : List Int -> TypeInfo -> msg
    , onClosed : List Int -> Bool -> msg
    , onRemove : List Int -> msg
    , viewError : Set (List Int)
    , closedBlocks : Set (List Int)
    , draggable : List Int -> List (Html.Attribute msg) -> List (Html msg) -> Html msg
    , droppable : List Int -> List (Html.Attribute msg) -> List (Html msg) -> Html msg 
    , currentDrag : Maybe (List Int)
    , currentDrop : Maybe (List Int)
    }

viewCodeElement 
    : VCEEvents msg
    -> CodeElement 
    -> VarEnvironment 
    -> Html msg 
viewCodeElement events element vars = 
    let (ne, ve, en) = checkValidity element vars AnyType
    in viewCodeElementEx events en ne ve []
    
viewCodeElementEx 
    : VCEEvents msg
    -> ErrorNode
    -> CodeElement
    -> VarEnvironment
    -> List Int
    -> Html msg
viewCodeElementEx events (ErrorNode node) element vars prefix =
    let edit = getEditInfo vars element
        type_ = getTypeOf element vars
        info = case Dict.get edit.key codeElements of
            Just i -> i 
            Nothing ->
                { key = edit.key
                , name = edit.key
                , desc = ""
                , type_ = type_
                , init = element
                }
        closed = Set.member prefix events.closedBlocks
        viewNode =
            if closed
            then ErrorNode
                <| (\l -> { errors = l, nodes = Dict.empty })
                <| List.concatMap
                    (\(p, e) -> List.map
                        (\sl -> p ++ ": " ++ sl)
                        e
                    )
                <| List.map 
                    (Tuple.mapFirst
                        (\p -> List.map String.fromInt p
                            |> List.intersperse ","
                            |> String.concat
                            |> \s -> "[" ++ s ++ "]"
                        )
                    )
                <| Dict.toList
                <| flattenNode 
                <| ErrorNode node
            else ErrorNode node
    in div 
        [ class 
            <| (++) "code-element-view " 
            <| case edit.category of 
                CCCalculation -> "calc"
                CCVariables -> "vars"
                CCBranches -> "branch"
                CCUtility -> "util"
        ]   
        [ div [ class "header" ]
            [ div 
                [ class 
                    <| (++) "closer" 
                    <| if closed then " closed" else ""
                , onClick 
                    <| events.onClosed prefix
                    <| not closed
                ]
                [ div [] [] ]
            , events.draggable prefix
                [ class "movable" ]
                [ div [ class "name" ]
                    [ text info.name ]
                , div [ class "preview" ]
                    [ text <| preview <| element ]
                , div [ class "type" ]
                    [ text <| typeString type_ ]
                ]
            , viewCurErrorNode
                (events.onViewError prefix)
                viewNode
                (Set.member prefix events.viewError)
            , div
                [ class "remover" 
                , HE.onClick <| events.onRemove prefix
                ]
                [ text "X" ]
            ]
        , if closed
            then text ""
            else div [ class "body" ]
                <| List.indexedMap
                    (\ind ->
                        let spath = prefix ++ [ ind ]
                        in viewEditEntry 
                            events
                            ( Maybe.withDefault
                                    (ErrorNode { errors = [], nodes = Dict.empty })
                                <| Dict.get ind node.nodes
                            )
                            spath
                            vars
                    )
                <| edit.entrys
        , if events.currentDrag /= Just prefix
            then text ""
            else div [ class "drag-overlay" ] []
        ]
    
viewEditEntry 
    : VCEEvents msg
    -> ErrorNode 
    -> List Int
    -> VarEnvironment
    -> CodeEditEntry
    -> Html msg 
viewEditEntry events node prefix vars entry = case entry of 
    CEEValue vn vi -> viewValueInfo
        events 
        node
        prefix
        vars
        vn
        vi
    CEEParameter pn pt -> viewParameter
        events
        node 
        prefix
        vars
        pn 
        pt
    CEEBlock bn bi -> viewCodeBlock
        events 
        node 
        prefix
        vars
        False
        bn
        bi
    CEEMath op -> viewOp 
        (events.onChange prefix << CEEMath)
        (events.onViewError prefix)
        node 
        (Set.member prefix events.viewError)
        op 
        [ (MOAdd, "+")
        , (MOSub, "-")
        , (MOMul, "*")
        , (MODiv, "/")
        ]
    CEECompare op -> viewOp 
        (events.onChange prefix << CEECompare)
        (events.onViewError prefix)
        node 
        (Set.member prefix events.viewError)
        op
        [ (COEq, "=")
        , (CONeq, "/=")
        , (COLt, "<")
        , (COLtEq, "<=")
        , (COGt, ">")
        , (COGtEq, ">=")
        ]
    CEEBool op -> viewOp 
        (events.onChange prefix << CEEBool)
        (events.onViewError prefix)
        node 
        (Set.member prefix events.viewError)
        op 
        [ (BOAnd, "and")
        , (BOOr, "or")
        , (BOXor, "xor")
        , (BONand, "nand")
        , (BONor, "nor")
        , (BONand, "xnor")
        ]
    CEEList new list -> viewEditList
        events
        node 
        prefix
        vars 
        new
        list

viewValueInfo
    : VCEEvents msg
    -> ErrorNode
    -> List Int
    -> VarEnvironment
    -> String
    -> ValueInfo
    -> Html msg 
viewValueInfo events node prefix vars varname info = div
    [ HA.classList 
        [ Tuple.pair "value-info-view" True 
        , Tuple.pair "dropable"
            <| events.currentDrag /= Nothing
        , Tuple.pair "focus"
            <| events.currentDrop == Just prefix
        ]
    ]
    [ events.droppable prefix
        [ class "header" ]
        [ div [ class "name" ]
            [ text varname ]
        , div [ class "type" ]
            [ text 
                <| (++) "Expected Type: "
                <| typeString info.desiredType 
            ]
        ]
    , div [ class "input" ]
        <| List.singleton
        <| case info.input of 
            VIEmpty -> events.droppable prefix 
                [ class "empty" ]
                [ text "No Input - select a type on the right"
                ]
            VIValue (VDInt v) -> events.droppable prefix 
                [ class "value int" ]
                [ Html.input
                    [ HA.type_ "number"
                    , HA.step "1"
                    , HA.value <| String.fromInt v 
                    , HE.onInput 
                        <| \input -> events.onChange prefix
                        <| CEEValue varname 
                        { info 
                        | input = VIValue 
                            <| VDInt 
                            <| Maybe.withDefault v  
                            <| String.toInt input
                        }
                    ] []
                ]
            VIValue (VDFloat v) -> events.droppable prefix 
                [ class "value float" ]
                [ Html.input 
                    [ HA.type_ "number"
                    , HA.step "any"
                    , HA.value <| String.fromFloat v
                    , HE.onInput 
                        <| \input -> events.onChange prefix
                        <| CEEValue varname 
                        { info 
                        | input = VIValue 
                            <| VDFloat
                            <| Maybe.withDefault v  
                            <| String.toFloat input
                        }
                    ] []
                ]
            VIValue (VDString v) -> events.droppable prefix 
                [ class "value string" ]
                [ Html.input
                    [ HA.type_ "text"
                    , HA.value v 
                    , HE.onInput 
                        <| \input -> events.onChange prefix
                        <| CEEValue varname 
                        { info 
                        | input = VIValue 
                            <| VDString input
                        }
                    ] []
                ]
            VIValue (VDBool v) -> events.droppable prefix 
                [ class "value bool" ]
                [ div [ class "buttons" ]
                    <| List.map 
                        (\(t,n) -> div 
                            [ class <| (++) n 
                                <| if t == v then " active" else ""
                            , HE.onClick
                                <| events.onChange prefix
                                <| CEEValue varname 
                                { info 
                                | input = VIValue 
                                    <| VDBool t
                                }
                            ]
                            [ text n ]
                        )
                    <| [ (True, "true"), (False, "false") ]
                ]
            VIValue (VDRoleKey v) -> events.droppable prefix 
                [ class "value RoleKey" ]
                [ Html.select 
                    [ HE.onInput
                        <| \input -> events.onChange prefix
                        <| CEEValue varname 
                        { info 
                        | input = VIValue 
                            <| VDRoleKey input
                        }
                    ]
                    <| List.map 
                        (\s -> Html.option 
                            [ HA.value s 
                            , HA.selected <| s == v 
                            ]
                            [ text s ]
                        )
                    <| Set.toList vars.roleKey
                ]
            VIValue (VDPhaseKey v) -> events.droppable prefix 
                [ class "value PhaseKey" ]
                [ Html.select 
                    [ HE.onInput
                        <| \input -> events.onChange prefix
                        <| CEEValue varname 
                        { info 
                        | input = VIValue 
                            <| VDPhaseKey input
                        }
                    ]
                    <| List.map 
                        (\s -> Html.option 
                            [ HA.value s 
                            , HA.selected <| s == v 
                            ]
                            [ text s ]
                        )
                    <| Set.toList vars.phaseKey
                ]
            VIValue (VDChatKey v) -> events.droppable prefix 
                [ class "value ChatKey" ]
                [ Html.select 
                    [ HE.onInput
                        <| \input -> events.onChange prefix
                        <| CEEValue varname 
                        { info 
                        | input = VIValue 
                            <| VDChatKey input
                        }
                    ]
                    <| List.map 
                        (\s -> Html.option 
                            [ HA.value s 
                            , HA.selected <| s == v 
                            ]
                            [ text s ]
                        )
                    <| Set.toList vars.chatKey
                ]
            VIValue (VDVotingKey v) -> events.droppable prefix 
                [ class "value VotingKey" ]
                [ Html.select 
                    [ HE.onInput
                        <| \input -> events.onChange prefix
                        <| CEEValue varname 
                        { info 
                        | input = VIValue 
                            <| VDVotingKey input
                        }
                    ]
                    <| List.map 
                        (\s -> Html.option 
                            [ HA.value s 
                            , HA.selected <| s == v 
                            ]
                            [ text s ]
                        )
                    <| Set.toList vars.votingKey
                ]
            VIVariable var -> events.droppable prefix 
                [ class "variable" ]
                [ Html.select 
                    [ HE.onInput 
                        <| \input -> events.onChange prefix 
                        <| CEEValue varname 
                        { info 
                        | input = VIVariable input 
                        }
                    ] 
                    <| List.map 
                        (\n -> Html.option 
                            [ HA.value n 
                            , HA.selected <| n == var
                            ]
                            [ text n ]
                        )
                    <| (if var == ""
                            then (::) ""
                            else identity
                        )
                    <| List.map Tuple.first
                    <| List.filter 
                        (\(_,d) -> canAdjustType d.type_ info.desiredType
                        )
                    <| Dict.toList vars.vars
                ]
            VIBlock element -> div [ class "block" ]
                [ viewCodeElementEx
                    events
                    ( case node of 
                        ErrorNode n -> Dict.get 0 n.nodes
                            |> Maybe.withDefault
                                (ErrorNode { errors = [], nodes = Dict.empty })
                    )
                    element
                    vars
                    (prefix ++ [0])
                ]
    -- , div
    ,   let cur = case info.input of 
                VIEmpty -> ""
                VIValue (VDInt _) -> "direct int"
                VIValue (VDFloat _) -> "direct float"
                VIValue (VDString _) -> "direct string"
                VIValue (VDBool _) -> "direct bool"
                VIValue (VDRoleKey _) -> "direct RoleKey"
                VIValue (VDPhaseKey _) -> "direct PhaseKey"
                VIValue (VDChatKey _) -> "direct ChatKey"
                VIValue (VDVotingKey _) -> "direct VotingKey"
                VIVariable _ -> "variable"
                VIBlock _ -> "block"
            types =
                [ Tuple.pair ""
                    <| Just VIEmpty
                , Tuple.pair "direct int"
                    <| if canAdjustType (TypeValue "int") info.desiredType
                        then Just <| VIValue <| VDInt 0
                        else Nothing
                , Tuple.pair "direct float"
                    <| if canAdjustType (TypeValue "float") info.desiredType
                        then Just <| VIValue <| VDFloat 0
                        else Nothing
                , Tuple.pair "direct string"
                    <| if canAdjustType (TypeValue "string") info.desiredType
                        then Just <| VIValue <| VDString ""
                        else Nothing
                , Tuple.pair "direct bool"
                    <| if canAdjustType (TypeValue "bool") info.desiredType
                        then Just <| VIValue <| VDBool False
                        else Nothing
                , Tuple.pair "direct RoleKey"
                    <| if canAdjustType (TypeValue "RoleKey") info.desiredType
                        then Just <| VIValue <| VDRoleKey 
                            <| Maybe.withDefault ""
                            <| List.head
                            <| Set.toList vars.roleKey
                        else Nothing
                , Tuple.pair "direct PhaseKey"
                    <| if canAdjustType (TypeValue "PhaseKey") info.desiredType
                        then Just <| VIValue <| VDPhaseKey 
                            <| Maybe.withDefault ""
                            <| List.head
                            <| Set.toList vars.phaseKey
                        else Nothing
                , Tuple.pair "direct ChatKey"
                    <| if canAdjustType (TypeValue "ChatKey") info.desiredType
                        then Just <| VIValue <| VDChatKey 
                            <| Maybe.withDefault ""
                            <| List.head
                            <| Set.toList vars.chatKey
                        else Nothing
                , Tuple.pair "direct VotingKey"
                    <| if canAdjustType (TypeValue "VotingKey") info.desiredType
                        then Just <| VIValue <| VDVotingKey 
                            <| Maybe.withDefault ""
                            <| List.head
                            <| Set.toList vars.votingKey
                        else Nothing
                , Tuple.pair "variable" 
                    <| Maybe.map (Tuple.first >> VIVariable)
                    <| List.head
                    <| List.filter 
                        (\(_,d) -> canAdjustType d.type_ info.desiredType
                        )
                    <| Dict.toList vars.vars
                , Tuple.pair "block" Nothing
                ]
                -- |> List.filter (\(n,c) -> n == "block" || c /= Nothing)
            onClick type_ = types 
                |> List.filter ((==) type_ << Tuple.first)
                |> List.head 
                |> Maybe.andThen
                    (\(n, val) -> case val of 
                        Nothing ->
                            if n == "block"
                            then Just <| events.onAddBlock prefix
                                info.desiredType
                            else Nothing
                        Just v -> Just <| events.onChange prefix
                            <| CEEValue varname 
                                { info | input = v }
                    )
                |> Maybe.withDefault 
                    ( events.onChange prefix 
                        <| CEEValue varname info
                    )
        in events.droppable prefix 
            [ class "input-selector" ] 
            <| List.singleton <| Html.select
            [ HE.onInput onClick
            , HA.title "select value source"
            ]
            <| List.map 
                (\(name, new) -> Html.option 
                    [ HA.value name 
                    , HA.selected <| name == cur 
                    , HA.disabled <| List.any identity 
                        [ name == "" && name /= cur
                        , new == Nothing && name /= "block"
                        ]
                    ]
                    [ if name == ""
                        then text "--select--" 
                        else text name 
                    ]
                )
            <| types
            
    , viewCurErrorNode
        (events.onViewError prefix)
        node
        (Set.member prefix events.viewError)
    ]

viewCodeBlock
    : VCEEvents msg
    -> ErrorNode
    -> List Int 
    -> VarEnvironment
    -> Bool
    -> String 
    -> CodeBlock
    -> Html msg 
viewCodeBlock events node prefix vars closable blockname block = 
    if Set.member prefix events.closedBlocks
    then div 
        [ class "code-block-view" ]
        [ div [ class "header" ]
            [ div []
                [ div 
                    [ class "name" 
                    , onClick 
                        <| events.onClosed prefix False
                    ]
                    [ text blockname ]
                , div [ class "spacer" ] []
                , viewCurErrorNode
                    (events.onViewError prefix)
                    ( ErrorNode
                        <| (\l -> { errors = l, nodes = Dict.empty })
                        <| List.concatMap
                            (\(p, e) -> List.map
                                (\sl -> p ++ ": " ++ sl)
                                e
                            )
                        <| List.map 
                            (Tuple.mapFirst
                                (\p -> List.map String.fromInt p
                                    |> List.intersperse ","
                                    |> String.concat
                                    |> \s -> "[" ++ s ++ "]"
                                )
                            )
                        <| Dict.toList
                        <| flattenNode 
                        <| node
                    ) 
                    (Set.member prefix events.viewError)
                , if closable
                    then div 
                        [ class "remover" 
                        , HE.onClick <| events.onRemove prefix
                        ]
                        [ text "X" ]
                    else text ""
                ]
            ]
        ]
    else div 
        [ class "code-block-view" ]
        [ div [ class "header" ]
            [ div []
                [ div 
                    [ class "name" 
                    , onClick 
                        <| events.onClosed prefix True
                    ]
                    [ text blockname ]
                , case block.return of 
                    Nothing -> text ""
                    Just rv -> div 
                        [ class "return" ]
                        [ text "return: "
                        , viewVariableInfo
                            (\v -> events.onChange prefix
                                <| CEEBlock blockname
                                    { block | return = Just v }
                            )
                            rv
                        ]
                , div [ class "spacer" ] []
                , viewCurErrorNode
                    (events.onViewError prefix)
                    node 
                    (Set.member prefix events.viewError)
                , if closable
                    then div 
                        [ class "remover" 
                        , HE.onClick <| events.onRemove prefix
                        ]
                        [ text "X" ]
                    else text ""
                ]
            , div [ class "input-vars" ]
                <| List.indexedMap
                    (\ind -> viewVariableInfo
                        (\nv -> events.onChange prefix 
                            <| CEEBlock blockname
                            { block
                            | vars = block.vars 
                                |> List.indexedMap
                                    (\i ov -> 
                                        if i == ind 
                                        then nv 
                                        else ov
                                    )
                            }
                        )
                    )
                <| block.vars
            ]
        , div [ class "body" ]
            <|  (\list -> (++) list
                    <| List.singleton
                    <| div [ class "adder-space" ]
                    <| List.singleton
                    <| div 
                        [ class "adder" 
                        , HA.title "add new item"
                        , HE.onClick <| events.onAddBlock
                            prefix
                            AnyType
                        ]
                        [ text "+" ]
                )
            -- <| List.intersperse
            --     ( div [ class "spacer" ] [])
            <| viewCodeBlockDropper events prefix
            <| Tuple.second
            <| List.foldl
                (\(ind,element) (lvars, returns) -> Tuple.pair 
                    ( case element of 
                        CESetTo vi vk ->
                            { lvars
                            | vars = Dict.insert vk 
                                { redefinition = case Dict.get vk lvars.vars of 
                                    Just od -> od.redefinition + 1
                                    Nothing -> 0
                                , type_ = getTypeOfValue vi.input lvars
                                , readonly = False
                                }
                                lvars.vars
                            }
                        CEPut vk vi ->
                            { lvars
                            | vars = Dict.insert vk 
                                { redefinition = case Dict.get vk lvars.vars of 
                                    Just od -> od.redefinition + 1
                                    Nothing -> 0
                                , type_ = getTypeOfValue vi.input lvars
                                , readonly = False
                                }
                                lvars.vars
                            }
                        _ -> lvars
                    )
                    <| returns ++
                        [ viewCodeElementEx
                            events 
                            (case node of 
                                ErrorNode ei -> Dict.get ind ei.nodes
                                    |> Maybe.withDefault
                                        ( ErrorNode 
                                            { errors = []
                                            , nodes = Dict.empty 
                                            }
                                        )
                            )
                            element
                            lvars 
                            (prefix ++ [ind])
                        ]
                )
                ( List.foldl
                    (\vi lvar ->
                        { lvar 
                        | vars = Dict.insert vi.key 
                            { redefinition = case Dict.get vi.key lvar.vars of 
                                Just od -> od.redefinition + 1
                                Nothing -> 0
                            , type_ = vi.type_
                            , readonly = False
                            }
                            lvar.vars
                        }
                    )
                    vars
                    <| (++) block.vars
                    <| Maybe.withDefault []
                    <| Maybe.map List.singleton block.return
                , []
                )
            <| List.indexedMap Tuple.pair
            <| block.elements
        ]

viewCodeBlockDropper : VCEEvents msg -> List Int -> List (Html msg) -> List (Html msg) 
viewCodeBlockDropper events path list = 
    let length = List.length list
        spacer : List Int -> Html msg 
        spacer spath = events.droppable spath
            [ HA.classList
                [ Tuple.pair "spacer" True 
                , Tuple.pair "expand" 
                    <| events.currentDrag /= Nothing
                , Tuple.pair "focus"
                    <| events.currentDrop == Just spath
                , Tuple.pair "first" 
                    <| (==) (Just 0)
                    <| LE.last spath
                , Tuple.pair "last"
                    <| (==) (Just length)
                    <| LE.last spath
                ]
            , HA.title <|
                if events.currentDrag /= Nothing
                then "Insert element here"
                else ""
            ]
            [ div [] [] ]
        mkpath : Int -> List Int 
        mkpath p = path ++ [ p ]
    in list 
        |> List.indexedMap
            (\ind e ->
                [ e
                , spacer <| mkpath <| ind + 1 
                ]
            )
        |> List.concat
        |> (::) (spacer <| mkpath 0)
    
viewVariableInfo : (VariableInfo -> msg) -> VariableInfo -> Html msg 
viewVariableInfo onChange var = div 
    [ class "variable-info-view" ]
    [ Html.input 
        [ HA.type_ "text"
        , HA.value var.key
        , HE.onInput <| \k -> onChange { var | key = k }
        ] []
    , div [ class "splitter" ] [ text ":" ]
    , div [ class "type" ] [ text <| typeString var.type_ ]
    ]

viewParameter
    : VCEEvents msg
    -> ErrorNode
    -> List Int 
    -> VarEnvironment
    -> String 
    -> TypeInfo
    -> Html msg 
viewParameter events node prefix vars parname type_ = div 
    [ class "parameter-view" ]
    [ div [ class "header" ]
        [ text "Parameter: "]
    , Html.input 
        [ HA.type_ "text"
        , HA.value parname
        , HE.onInput 
            <| \name -> events.onChange prefix
            <| CEEParameter name type_
        ] []
    , div [ class "type" ]
        [ text <| typeString type_ ]
    , viewCurErrorNode
        (events.onViewError prefix)
        node
        (Set.member prefix events.viewError)
    ]

viewOp 
    : (a -> msg) 
    -> (Bool -> msg)
    -> ErrorNode 
    -> Bool
    -> a 
    -> List (a, String) 
    -> Html msg 
viewOp onChange onViewError node viewError selOp opList = div 
    [ class "operator-view" ]
    [ Html.select 
        [ class "select" 
        , HE.onInput <| \strName -> opList
            |> List.filter (Tuple.second >> (==) strName)
            |> List.head 
            |> Maybe.map Tuple.first 
            |> Maybe.withDefault selOp 
            |> onChange
        ]
        <| List.map 
            (\(op, name) -> Html.option
                [ class "option"
                , HA.selected <| selOp == op
                , HA.value name
                ]
                [ text name ]
            )
        <| opList
    , viewCurErrorNode onViewError node viewError
    ]

viewEditList
    : VCEEvents msg
    -> ErrorNode
    -> List Int 
    -> VarEnvironment
    -> CodeEditEntry
    -> List CodeEditEntry
    -> Html msg 
viewEditList events (ErrorNode node) prefix vars new list = div 
    [ class "edit-list-view"
    ]
    [ div [ class "body" ]
        <| List.indexedMap
            (\ind e -> div [ class "entry" ]
                [ viewEditEntry   
                    events
                    ( Dict.get ind node.nodes
                        |> Maybe.withDefault
                            (ErrorNode { errors = [], nodes = Dict.empty })
                    )
                    ( prefix ++ [ ind ] )
                    vars 
                    e
                , div 
                    [ class "adder" 
                    , HA.title <| (++) "add new entry before value "
                        <| String.fromInt ind
                    , onClick 
                        <| events.onChange prefix
                        <| CEEList new 
                        <| List.take ind list ++ [ new ] ++ List.drop ind list
                    ]
                    [ text "+" ]
                , div 
                    [ class "remover" 
                    , HA.title <| (++) "remove value "
                        <| String.fromInt ind
                    , onClick 
                        <| events.onChange prefix
                        <| CEEList new 
                        <| LE.removeAt ind 
                        <| list
                    ]
                    [ text "X" ]
                ]
            )
        <| list
    , div 
        [ class "adder" 
        , onClick 
            <| events.onChange prefix
            <| CEEList new 
            <| list ++ [ new ]
        ]
        [ text "add new item"
        ]
    ]

viewCurErrorNode : (Bool -> msg) -> ErrorNode -> Bool -> Html msg 
viewCurErrorNode onViewInfo (ErrorNode node) viewInfo = 
    if List.isEmpty node.errors
    then text ""
    else div 
        [ class "error-node" 
        ]
        [ div 
            [ class "indicator"
            , HE.onClick <| onViewInfo <| not viewInfo
            ]
            [ text <| String.fromInt <| List.length node.errors ]
        , div 
            [ class <| (++) "info" 
                <| if viewInfo then " active" else ""
            ]
            <| List.map 
                (\e -> div 
                    [ class "error" ]
                    [ text e ]
                )
            <| node.errors
        ]