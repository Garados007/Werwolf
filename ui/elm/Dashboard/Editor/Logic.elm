module Dashboard.Editor.Logic exposing 
    ( BoolOperator (..)
    , CodeBlock
    , CodeCategory (..)
    , CodeEditEntry (..)
    , CodeElement (..)
    , CodeElementEditInfo
    , CodeElementInfo
    , CodeEnvironment
    , CodeEnvironmentBlockType (..)
    , CodeEnvironmentPath (..)
    , CompareOperator (..)
    , ErrorNode (..)
    , MathOperator (..)
    , TypeInfo (..)
    , ValueDirect (..)
    , ValueInfo
    , ValueInput (..)
    , VarDefinition
    , VarEnvironment
    , VariableInfo
    , addClipboard
    , addEmptyCodeEnvironment
    , canAdjustType
    , checkBlockValidity
    , checkValidity
    , codeElements
    , createPathList
    , deepAdd
    , deepDelete
    , deepEdit
    , deepGet
    , flattenNode
    , getCEBlock
    , getCEPath
    , getEditInfo
    , getTypeOf
    , getTypeOfValue
    , injectPath
    , isNodeEmpty
    , isPrefix
    , mapCodeEnvironment
    , newCodeEnvironment
    , preview
    , pushEdit
    , removePath
    , removeRootCodeBlock
    , setCEPath
    , typeString
    )

import Dict exposing (Dict)
import Set exposing (Set)
import Json.Encode exposing (Value)
import List.Extra as LE
import Regex

type TypeInfo
    = AnyType
    | TypeValue String 
    | TypeList (List TypeInfo)

-- variables that given from the outer scope
type alias VariableInfo =
    -- user defined variable name
    { key : String
    , type_ : TypeInfo
    , readonly : Bool 
    }

-- input value information
type alias ValueInfo =
    { input : ValueInput
    , desiredType : TypeInfo
    } 

type ValueInput
    = VIEmpty
    | VIValue ValueDirect
    | VIVariable String
    | VIBlock CodeElement

type ValueDirect
    = VDInt Int 
    | VDFloat Float 
    | VDString String
    | VDBool Bool
    | VDRoleKey String 
    | VDPhaseKey String 
    | VDChatKey String 
    | VDVotingKey String

type alias CodeBlock = 
    { elements: List CodeElement
    , vars: List VariableInfo
    , return: Maybe VariableInfo
    }

type MathOperator
    = MOAdd
    | MOSub
    | MOMul
    | MODiv

type CompareOperator
    = COEq
    | CONeq
    | COLt 
    | COLtEq 
    | COGt 
    | COGtEq

type BoolOperator
    = BOAnd
    | BOOr 
    | BOXor
    | BONand 
    | BOXnor 
    | BONor

type CodeElement
    = CESetTo ValueInfo String
    | CEMath ValueInfo MathOperator ValueInfo
    | CECompare ValueInfo CompareOperator ValueInfo
    | CEBoolOp ValueInfo BoolOperator ValueInfo
    | CEConcat ValueInfo ValueInfo
    | CEListGet ValueInfo ValueInfo
    | CEDictGet ValueInfo ValueInfo 
    | CETupleFirst ValueInfo
    | CETupleSecond ValueInfo 
    | CEUnwrapMaybe ValueInfo CodeBlock CodeBlock
    | CEIf ValueInfo CodeBlock CodeBlock
    | CEFor ValueInfo ValueInfo ValueInfo CodeBlock
    | CEWhile ValueInfo CodeBlock
    | CEBreak
    | CEForeachList ValueInfo CodeBlock
    | CEForeachDict ValueInfo CodeBlock
    | CEEndGame
    | CEJust ValueInfo
    | CENothing
    | CEList (List ValueInfo)
    | CEPut String ValueInfo 
    | CEGetPlayer ValueInfo ValueInfo
    | CESetRoomPermission ValueInfo ValueInfo ValueInfo ValueInfo
    | CEInformVoting ValueInfo ValueInfo ValueInfo
    | CEAddRoleVisibility ValueInfo ValueInfo ValueInfo
    | CEFilterTopScore ValueInfo
    | CEFilterPlayer ValueInfo ValueInfo ValueInfo
    | CEPlayerId ValueInfo
    | CEPlayerAlive ValueInfo
    | CEPlayerExtraWolfLive ValueInfo
    | CEPlayerHasRole ValueInfo ValueInfo
    | CEPlayerAddRole ValueInfo ValueInfo
    | CEPlayerRemoveRole ValueInfo ValueInfo    

type alias CodeElementInfo =
    { key : String
    , name : String
    , desc : String
    , type_ : TypeInfo
    , init : CodeElement
    }

type alias VarDefinition =
    { redefinition : Int
    , type_ : TypeInfo
    , readonly : Bool
    }

type ErrorNode = ErrorNode 
    { errors : List String
    , nodes : Dict Int ErrorNode
    }

type alias VarEnvironment =
    { vars : Dict String VarDefinition
    , chatKey : Set String
    , phaseKey : Set String
    , roleKey : Set String 
    , votingKey : Set String
    }

canAdjustType : TypeInfo -> TypeInfo -> Bool 
canAdjustType sourceType targetType = case (sourceType, targetType) of
    (AnyType, _) -> True 
    (_, AnyType) -> True
    (TypeValue sv, TypeValue tv) -> 
        if sv == tv 
        then True
        else List.member sv <| case tv of 
            "num" -> [ "int", "float" ]
            "concatable" -> [ "int", "float", "string" ]
            "comparable" -> [ "int", "float", "string", "bool", "PlayerId" ]
            "string" -> [ "RoleKey", "PhaseKey", "ChatKey", "VotingKey" ]
            _ -> []
    (TypeList (s::ss), TypeList (t::ts)) -> canAdjustType s t 
        && canAdjustType (TypeList ss) (TypeList ts)
    (TypeList [], TypeList []) -> True
    (TypeList [s], TypeValue tv) -> canAdjustType s (TypeValue tv)
    (TypeValue sv, TypeList [t]) -> canAdjustType (TypeValue sv) t
    _ -> False 

typeString : TypeInfo -> String 
typeString type_ = case type_ of 
    AnyType -> "null"
    TypeValue tv -> "'" ++ tv ++ "'"
    TypeList tl -> "[" ++
        ( List.map typeString tl 
            |> List.intersperse ","
            |> String.concat
        )
        ++ "]"

getTypeOfValue : ValueInput -> VarEnvironment -> TypeInfo 
getTypeOfValue value defs = case value of 
    VIEmpty -> AnyType
    VIValue (VDInt _) -> TypeValue "int"
    VIValue (VDFloat _) -> TypeValue "float"
    VIValue (VDString _) -> TypeValue "string"
    VIValue (VDBool _) -> TypeValue "bool"
    VIValue (VDRoleKey _) -> TypeValue "RoleKey"
    VIValue (VDPhaseKey _) -> TypeValue "PhaseKey"
    VIValue (VDChatKey _) -> TypeValue "ChatKey"
    VIValue (VDVotingKey _) -> TypeValue "VotingKey"
    VIVariable k -> case Dict.get k defs.vars of 
        Just v -> v.type_
        Nothing -> AnyType
    VIBlock b -> getTypeOf b defs

getTypeOf : CodeElement -> VarEnvironment -> TypeInfo
getTypeOf element defs = case element of 
    CESetTo _ _  -> TypeList []
    CEMath v1 _ v2 ->
        if canAdjustType (getTypeOfValue v1.input defs) (TypeValue "int")
            && canAdjustType (getTypeOfValue v2.input defs) (TypeValue "int")
        then TypeValue "int"
        else TypeValue "float"
    CECompare _ _ _ -> TypeValue "bool"
    CEBoolOp _ _ _ -> TypeValue "bool"
    CEConcat _ _ -> TypeValue "string"
    CEListGet v _ -> case getTypeOfValue v.input defs of 
        TypeList [ TypeValue "list", t ] -> TypeList [ TypeValue "maybe", t ]
        _ -> TypeList [ TypeValue "maybe", AnyType ]
    CEDictGet v _ -> case getTypeOfValue v.input defs of 
        TypeList [ TypeValue "dict", _, t ] -> TypeList [ TypeValue "maybe", t ]
        _ -> TypeList [ TypeValue "maybe", AnyType ]
    CETupleFirst v -> case getTypeOfValue v.input defs of 
        TypeList [ TypeValue "tuple", t, _ ] -> t 
        _ -> AnyType
    CETupleSecond v -> case getTypeOfValue v.input defs of 
        TypeList [ TypeValue "tuple", _, t ] -> t 
        _ -> AnyType
    CEUnwrapMaybe _ _ _ -> TypeList []
    CEIf _ _ _  -> TypeList []
    CEFor _ _ _ _ -> TypeList []
    CEWhile _ _ -> TypeList []
    CEBreak -> TypeList []
    CEForeachList _ _ -> TypeList []
    CEForeachDict _ _ -> TypeList []
    CEEndGame -> TypeList []
    CEJust v -> TypeList 
        [ TypeValue "maybe"
        , getTypeOfValue v.input defs
        ]
    CENothing -> TypeList [ TypeValue "maybe", AnyType ]
    CEList list -> List.map (\v -> getTypeOfValue v.input defs) list 
        |> (\l -> case l of 
                [] -> []
                h::[] -> [ h ]
                h::ls -> 
                    if List.all (canAdjustType h) ls 
                    then [ h ]
                    else []
            )
        |> List.head 
        |> Maybe.withDefault AnyType
        |> \t -> TypeList [ TypeValue "list", t ]
    CEPut _ _ -> TypeList []
    CEGetPlayer _ _ -> TypeList [ TypeValue "list", TypeValue "Player" ]
    CESetRoomPermission _ _ _ _ -> TypeList []
    CEInformVoting _ _ _ -> TypeList []
    CEAddRoleVisibility _ _ _ -> TypeList []
    CEFilterTopScore _ -> TypeList [ TypeValue "list", TypeValue "Player" ]
    CEFilterPlayer _ _ _ -> TypeList [ TypeValue "list", TypeValue "Player" ]
    CEPlayerId _ -> TypeValue "PlayerId"
    CEPlayerAlive _ -> TypeValue "bool"
    CEPlayerExtraWolfLive _ -> TypeValue "bool"
    CEPlayerHasRole _ _ -> TypeValue "bool"
    CEPlayerAddRole _ _ -> TypeList []
    CEPlayerRemoveRole _ _ -> TypeList []

isNodeEmpty : ErrorNode -> Bool
isNodeEmpty (ErrorNode node) =
    List.isEmpty node.errors
    && Dict.isEmpty node.nodes

flattenNode : ErrorNode -> Dict (List Int) (List String)
flattenNode (ErrorNode node) = node.nodes
    |> Dict.map 
        (\k n -> flattenNode n
            |> Dict.toList
            |> List.map (Tuple.mapFirst <| (::) k)
        )
    |> Dict.values 
    |> List.concat
    |> (if List.isEmpty node.errors
        then identity
        else (::) ([], node.errors)
    )
    |> Dict.fromList

-- begin region: helper vor checkValidity

addVariable 
    : String -> TypeInfo 
    -> (tar, VarEnvironment, ErrorNode) 
    -> (tar, VarEnvironment, ErrorNode)
addVariable name type_ (elem, var, ErrorNode info) =
    ( case Dict.get name var.vars of 
        Just vd ->
            (   { var 
                | vars = Dict.insert name
                    { redefinition = vd.redefinition + 1
                    , type_  = type_ 
                    , readonly = False
                    }
                    var.vars
                }
            , List.filterMap (identity)
                [ if canAdjustType type_ vd.type_
                    then Nothing
                    else Just <| String.concat
                        [ "variable was already defined with type "
                        , typeString vd.type_
                        , " but now you want to assign "
                        , typeString type_
                        ]
                , if vd.readonly 
                    then Just <| String.concat 
                        [ "cannot overwrite readonly variable "
                        , name
                        ]
                    else Nothing
                ]
            )
        Nothing ->
            (   { var 
                | vars = Dict.insert name 
                    { redefinition = 0
                    , type_ = type_
                    , readonly = False
                    }
                    var.vars
                }
            , []
            )
    )
    |> \(nvar, nerror) ->
        ( elem
        , nvar 
        , ErrorNode 
            { info 
            | errors = nerror ++ info.errors
            }
        )

walkDirect 
    : ValueInfo 
    -> VarEnvironment
    -> (ValueInfo, ErrorNode)
walkDirect value vars = 
    let list : List String -> ValueInput-> (ValueInput, ErrorNode)
        list texts var = Tuple.pair var 
            <| ErrorNode 
                { errors = texts
                , nodes = Dict.empty 
                }
        empty : ValueInput -> (ValueInput, ErrorNode)
        empty = list []
        single : String -> ValueInput-> (ValueInput, ErrorNode)
        single text = list [ text ]
        checkKeys : (VarEnvironment -> Set String) -> String -> ValueDirect -> (ValueInput, ErrorNode)
        checkKeys getSet key val = list 
            (List.filterMap identity
                [ if Set.member key <| getSet vars
                    then Nothing
                    else Just "value not found"
                , if Set.isEmpty <| getSet vars 
                    then Just "no possible values are defined"
                    else Nothing
                ]
            )
            <| VIValue val
        (ni, ErrorNode nn) = case value.input of 
            VIEmpty -> single "No value inserted" VIEmpty
            VIValue (VDRoleKey key) -> checkKeys .roleKey key 
                <| VDRoleKey key
            VIValue (VDPhaseKey key) -> checkKeys .phaseKey key 
                <| VDPhaseKey key 
            VIValue (VDChatKey key) -> checkKeys .chatKey key 
                <| VDChatKey key
            VIValue (VDVotingKey key) -> checkKeys .votingKey key 
                <| VDVotingKey key 
            VIValue v -> empty <| VIValue v
            VIVariable v ->
                if Dict.member v vars.vars 
                then empty <| VIVariable v
                else single "reference not found" <| VIVariable v
            VIBlock b -> checkValidity b vars value.desiredType
                |> \( nb, nv, nn_ ) ->
                    ( VIBlock nb 
                    , ErrorNode
                        { errors = []
                        , nodes = Dict.singleton 0 nn_
                        }
                    )
    in  if canAdjustType 
            (getTypeOfValue value.input vars) 
            value.desiredType
        then
            ( { value | input = ni }
            , ErrorNode nn 
            )
        else 
            ( { value | input = ni }
            , ErrorNode 
                { nn 
                | errors = String.concat
                    [ "Value type "
                    , typeString value.desiredType
                    , " was expected but got "
                    , typeString <| getTypeOfValue value.input vars
                    ]
                    :: nn.errors
                }
            )

checkStart : tar -> VarEnvironment  -> (tar, VarEnvironment, ErrorNode)
checkStart func vars =
    ( func 
    , vars 
    , ErrorNode 
        { errors = []
        , nodes = Dict.empty
        }
    )

checkValues 
    : ValueInfo 
    -> Int 
    -> (ValueInfo -> tar, VarEnvironment, ErrorNode)
    -> (tar, VarEnvironment, ErrorNode)
checkValues value index (mod, vars, ErrorNode node) =
    walkDirect value vars 
    |> \(nvalue, snode) ->
        ( mod nvalue
        , vars 
        , ErrorNode 
            { node
            | nodes = 
                if isNodeEmpty snode
                then node.nodes
                else Dict.insert index snode node.nodes
            }
        )

checkInsert
    : val
    -> (val -> tar, VarEnvironment, ErrorNode)
    -> (tar, VarEnvironment, ErrorNode)
checkInsert val (mod, vars, node) = (mod val, vars, node)

checkBlock
    : CodeBlock 
    -> Int 
    -> (CodeBlock -> tar, VarEnvironment, ErrorNode)
    -> (tar, VarEnvironment, ErrorNode)
checkBlock block index (mod, vars, ErrorNode node) =
    let (nvars, verror) = List.foldl 
            (\var (vd, err) ->
                ( Dict.insert var.key 
                    { redefinition = 0
                    , type_ = var.type_
                    , readonly = True
                    }
                    vd
                , (++) err 
                    <| List.filterMap identity
                    [ if Dict.member var.key vd
                        then Just <| String.concat
                            [ "block variable "
                            , var.key
                            , " cannot overwrite previosly defined variable"
                            ]
                        else Nothing
                    , if Regex.fromString "^[_a-zA-Z][_a-zA-Z0-9]{0,19}$"
                            |> Maybe.withDefault Regex.never 
                            |> \r -> Regex.contains r var.key 
                        then Nothing
                        else Just <| String.concat 
                            [ "block variable '"
                            , var.key
                            , "' doesn't match the pattern "
                            , "^[_a-zA-Z][_a-zA-Z0-9]{0,19}$"
                            ]
                    ]
                )
            )
            (vars.vars, [])
            block.vars
        (nvars2, rerror) = case block.return of 
            Just var ->
                ( Dict.insert var.key 
                    { redefinition = 0
                    , type_ = var.type_
                    , readonly = False
                    }
                    nvars
                , if Dict.member var.key nvars
                    then List.singleton <| String.concat
                        [ "return variable "
                        , var.key
                        , " cannot overwrite previosly defined variable"
                        ] 
                    else []
                )
            Nothing -> (nvars, [])
        (elements, fvars, nodes) = List.foldl 
            (\element (list, v, no) -> checkValidity element v AnyType
                |> \(ne, nv, n) ->
                ( list ++ [ ne ]
                , nv
                , if isNodeEmpty n 
                    then no 
                    else Dict.insert (List.length list) n no
                )
            )
            ( []
            , { vars | vars = nvars }
            , Dict.empty
            )
            block.elements
        newNode = ErrorNode
            { errors = verror ++ rerror
            , nodes = nodes
            }
    in  ( mod
            { block
            | elements = elements
            }
        , vars -- do not use internal variables !!!
        , ErrorNode 
            { node
            | nodes = 
                if isNodeEmpty newNode
                then node.nodes
                else Dict.insert index newNode node.nodes
            }
        )
    
desired : TypeInfo -> TypeInfo -> TypeInfo 
desired expected input =
    if canAdjustType input expected
    then input
    else expected

checkDesiredValues 
    : ValueInfo 
    -> Int 
    -> TypeInfo
    -> (ValueInfo -> tar, VarEnvironment, ErrorNode)
    -> (tar, VarEnvironment, ErrorNode)
checkDesiredValues value index type_ = checkValues
    { value
    | desiredType = type_ 
    }
    index

addError 
    : Maybe String 
    -> (tar, VarEnvironment, ErrorNode)
    -> (tar, VarEnvironment, ErrorNode)
addError error (mod, vars, ErrorNode node) =
    ( mod 
    , vars 
    , ErrorNode 
        { node 
        | errors = case error of 
            Just e -> node.errors ++ [ e ]
            Nothing -> node.errors
        }
    )

addErrorAt
    : Int 
    -> Maybe String 
    -> (tar, VarEnvironment, ErrorNode)
    -> (tar, VarEnvironment, ErrorNode)
addErrorAt index error (mod, vars, ErrorNode node) =
    ( mod 
    , vars 
    , ErrorNode 
        { node 
        | nodes = Dict.get index node.nodes 
            |> Maybe.withDefault 
                (ErrorNode { errors = [], nodes = Dict.empty })
            |>  (\(ErrorNode n) -> ErrorNode
                    { n 
                    | errors = case error of 
                        Just e -> n.errors ++ [ e ]
                        Nothing -> n.errors
                    }
                )
            |> (\d -> Dict.insert index d node.nodes)
        }
    )

checkExpectedType 
    : TypeInfo 
    -> (CodeElement, VarEnvironment, ErrorNode)
    -> (CodeElement, VarEnvironment, ErrorNode)
checkExpectedType expected (element, vars, node)= addError
    (getTypeOf element vars
        |> \type_ -> 
            if canAdjustType type_ expected
            then Nothing
            else Just 
                <| "cannot transform type "
                ++ typeString type_ 
                ++ " to "
                ++ typeString expected
    )
    (element, vars, node)

-- end region: helper vor checkValidity

{-| Checks if the given code element has no errors and add type information at
    the variable nodes.
    Store all errors in the ErrorNode as trees to select them faster.
-}
checkValidity 
    : CodeElement 
    -> VarEnvironment
    -> TypeInfo
    -> (CodeElement, VarEnvironment, ErrorNode)
checkValidity element vars expectedType = checkExpectedType expectedType <| case element of 
    CESetTo val key -> checkStart CESetTo vars
        |> checkValues val 0
        |> addVariable key (getTypeOfValue val.input vars)
        |> addErrorAt 1
            ( if Regex.fromString 
                    "^[_a-zA-Z][_a-zA-Z0-9]{0,19}$"
                |> Maybe.withDefault Regex.never 
                |> \r -> Regex.contains r key
            then Nothing
            else Just "invalid characters for this parameter. only this format is supported ^[_a-zA-Z][_a-zA-Z0-9]{0,19}$"
            )
        |> checkInsert key
    CEMath val1 op val2 -> checkStart CEMath vars 
        |> checkDesiredValues val1 0 (TypeValue "num")
        |> checkInsert op 
        |> checkDesiredValues val2 2 (TypeValue "num")
    CECompare val1 op val2 -> 
        let t1 = getTypeOfValue val1.input vars
            t2 = getTypeOfValue val2.input vars
            both = 
                if canAdjustType t1 (TypeValue "num")
                    && canAdjustType t2 (TypeValue "num")
                then TypeValue "num"
                else desired (TypeValue "comparable")
                        <| desired t1 t2
        in checkStart CECompare vars 
            |> checkDesiredValues val1 0 both
            |> checkInsert op 
            |> checkDesiredValues val2 2 both
    CEBoolOp val1 op val2 -> checkStart CEBoolOp vars 
        |> checkDesiredValues val1 0 (TypeValue "bool")
        |> checkInsert op 
        |> checkDesiredValues val2 2 (TypeValue "bool")
    CEConcat val1 val2 -> checkStart CEConcat vars 
        |> checkDesiredValues val1 0 (TypeValue "concatable")
        |> checkDesiredValues val2 1 (TypeValue "concatable")
    CEListGet val1 val2 -> 
        let vt1 = case expectedType of  
                TypeList [ TypeValue "maybe", t ] -> TypeList [ TypeValue "list", t ]
                _ -> TypeList [ TypeValue "list", AnyType ]
        in checkStart CEListGet vars 
            |> checkDesiredValues val1 0 vt1
            |> checkDesiredValues val2 1 (TypeValue "int")
    CEDictGet val1 val2 ->
        let vt1 = case expectedType of 
                TypeList [ TypeValue "maybe", t ] ->
                    TypeList [ TypeValue "dict", AnyType, t ]
                _ -> TypeList [ TypeValue "dict", AnyType, AnyType ]
            kt = case getTypeOfValue val1.input vars of
                TypeList [ TypeValue "dict", t, _ ] -> t 
                _ -> AnyType
        in checkStart CEDictGet vars 
            |> checkDesiredValues val1 0 vt1
            |> checkDesiredValues val2 1 kt
    CETupleFirst val -> checkStart CETupleFirst vars 
        |> checkDesiredValues val 0
            (TypeList [ TypeValue "tuple", expectedType, AnyType ])
    CETupleSecond val -> checkStart CETupleSecond vars
        |> checkDesiredValues val 0 
            (TypeList [ TypeValue "tuple", AnyType, expectedType ])
    CEUnwrapMaybe val block1 block2 -> checkStart CEUnwrapMaybe vars
        |> checkDesiredValues val 0 
            (TypeList [ TypeValue "maybe", AnyType ])
        |> checkBlock 
            { block1 
            | vars = List.indexedMap
                (\ind v -> case ind of 
                    0 -> 
                        { v 
                        | type_ = case getTypeOfValue val.input vars of 
                            (TypeList [ TypeValue "maybe", t]) -> t 
                            _ -> AnyType
                        }
                    _ -> v
                )
                block1.vars
            }
            1
        |> checkBlock block2 2
    CEIf val block1 block2 -> checkStart CEIf vars 
        |> checkDesiredValues val 0 (TypeValue "bool")
        |> checkBlock block1 1
        |> checkBlock block2 2
    CEFor val1 val2 val3 block -> checkStart CEFor vars
        |> checkDesiredValues val1 0 (TypeValue "num")
        |> checkDesiredValues val2 1 (TypeValue "num")
        |> checkDesiredValues val3 2 (TypeValue "num")
        |> checkBlock block 3
    CEWhile val block -> checkStart CEWhile vars
        |> checkDesiredValues val 0 (TypeValue "bool")
        |> checkBlock block 1
    CEBreak -> checkStart CEBreak vars 
    CEForeachList val block -> checkStart CEForeachList vars 
        |> checkDesiredValues val 0 (TypeList [ TypeValue "list", AnyType ])
        |> checkBlock 
            { block 
            | vars = List.indexedMap
                (\ind v -> case ind of 
                    0 -> 
                        { v 
                        | type_ = case getTypeOfValue val.input vars of 
                            (TypeList [ TypeValue "list", t]) -> t 
                            _ -> AnyType
                        }
                    _ -> v
                )
                block.vars
            }
            1
    CEForeachDict val block -> checkStart CEForeachDict vars 
        |> checkDesiredValues val 0 (TypeList [ TypeValue "dict", AnyType, AnyType ])
        |> checkBlock 
            { block
            | vars = 
                ( case getTypeOfValue val.input vars of 
                    (TypeList [ TypeValue "dict", k, v]) -> (k, v)
                    _ -> (AnyType, AnyType)
                )
                |> \(k, v) -> List.indexedMap
                    (\ind v_ -> case ind of 
                        0 -> { v_ | type_ = k }
                        1 -> { v_ | type_ = v }
                        _ -> v_
                    )
                    block.vars
            } 1
    CEEndGame -> checkStart CEEndGame vars 
    CEJust val -> 
        let vt = case expectedType of 
                TypeList [ TypeValue "maybe", t ] -> t 
                _ -> AnyType
        in checkStart CEJust vars
            |> checkDesiredValues val 0 vt
    CENothing -> checkStart CENothing vars
    CEList vals ->
        let vt = case expectedType of 
                TypeList [ TypeValue "list", t ] -> t 
                _ -> List.head vals
                    |> Maybe.map (\v -> getTypeOfValue v.input vars)
                    |> Maybe.withDefault AnyType
            link : (a -> b) 
                -> (a, VarEnvironment, ErrorNode)
                -> (b, VarEnvironment, ErrorNode)
            link func (va, vv, ve) = (func va, vv, ve)
            embed : Int -> (a, b, ErrorNode) -> (a, b, ErrorNode)
            embed index (a, b, node) =
                ( a
                , b 
                , ErrorNode 
                    { errors = []
                    , nodes = Dict.singleton index node 
                    }
                )
            flip f b a = f a b
        in List.indexedMap Tuple.pair vals
            |> List.foldr
                (\(ind, it) -> link (flip (::))
                    >> checkDesiredValues it ind vt
                )
                (checkStart [] vars)
            |> embed 0
            |> link CEList
    CEPut key val ->
        let vt = Dict.get key vars.vars |> Maybe.map .type_
            ne = 
                if vt == Nothing
                then List.singleton <| String.concat
                    [ "Variable "
                    , key
                    , " wasn't defined"
                    ]
                else []
        in checkStart CEPut vars 
            |> \( vp, vv, ErrorNode ve) ->
                ( vp
                , vv 
                , ErrorNode { ve | errors = ne ++ ve.errors }
                )
            |> checkInsert key 
            |> checkDesiredValues val 1 (Maybe.withDefault AnyType vt)
    CEGetPlayer val1 val2 -> checkStart CEGetPlayer vars
        |> checkDesiredValues val1 0 
            ( TypeList 
                [ TypeValue "maybe"
                , TypeList [ TypeValue "list", TypeValue "RoleKey" ]
                ]
            )
        |> checkDesiredValues val2 1 (TypeValue "bool")
    CESetRoomPermission val1 val2 val3 val4 -> checkStart CESetRoomPermission vars
        |> checkDesiredValues val1 0 (TypeValue "ChatKey")
        |> checkDesiredValues val2 1 (TypeValue "bool")
        |> checkDesiredValues val3 2 (TypeValue "bool")
        |> checkDesiredValues val4 3 (TypeValue "bool")
    CEInformVoting val1 val2 val3 -> checkStart CEInformVoting vars
        |> checkDesiredValues val1 0 (TypeValue "ChatKey")
        |> checkDesiredValues val2 1 (TypeValue "VoteKey")
        |> checkDesiredValues val3 2 (TypeList [ TypeValue "list", TypeValue "Player" ])
    CEAddRoleVisibility val1 val2 val3 -> checkStart CEAddRoleVisibility vars
        |> checkDesiredValues val1 0 (TypeList [ TypeValue "list", TypeValue "Player" ])
        |> checkDesiredValues val2 1 (TypeList [ TypeValue "list", TypeValue "Player" ])
        |> checkDesiredValues val3 2 (TypeList [ TypeValue "list", TypeValue "RoleKey" ])
    CEFilterTopScore val -> checkStart CEFilterTopScore vars
        |> checkDesiredValues val 0
            ( TypeList 
                [ TypeValue "list"
                , TypeList 
                    [ TypeValue "tuple"
                    , TypeValue "PlayerId"
                    , TypeValue "int"
                    ]
                ]
            )
    CEFilterPlayer val1 val2 val3 -> checkStart CEFilterPlayer vars 
        |> checkDesiredValues val1 0 (TypeList [ TypeValue "list", TypeValue "Player" ])
        |> checkDesiredValues val2 1 (TypeList [ TypeValue "list", TypeValue "RoleKey" ])
        |> checkDesiredValues val3 2 (TypeList [ TypeValue "list", TypeValue "RoleKey" ])
    CEPlayerId val -> checkStart CEPlayerId vars
        |> checkDesiredValues val 0 (TypeValue "Player")
    CEPlayerAlive val -> checkStart CEPlayerAlive vars
        |> checkDesiredValues val 0 (TypeValue "Player")
    CEPlayerExtraWolfLive val -> checkStart CEPlayerExtraWolfLive vars
        |> checkDesiredValues val 0 (TypeValue "Player")
    CEPlayerHasRole val1 val2 -> checkStart CEPlayerHasRole vars
        |> checkDesiredValues val1 0 (TypeValue "Player")
        |> checkDesiredValues val2 1 (TypeValue "RoleKey")
    CEPlayerAddRole val1 val2 -> checkStart CEPlayerAddRole vars
        |> checkDesiredValues val1 0 (TypeValue "Player")
        |> checkDesiredValues val2 1 (TypeValue "RoleKey")
    CEPlayerRemoveRole val1 val2 -> checkStart CEPlayerRemoveRole vars
        |> checkDesiredValues val1 0 (TypeValue "Player")
        |> checkDesiredValues val2 1 (TypeValue "RoleKey")

checkBlockValidity 
    : CodeBlock 
    -> VarEnvironment 
    -> (CodeBlock, VarEnvironment, ErrorNode)
checkBlockValidity block vars = 
    let en = ErrorNode { errors = [], nodes = Dict.empty }
        (cb, ve, ErrorNode rn) = checkBlock block 0 
            (identity, vars, en)
    in  ( cb
        , ve
        , Maybe.withDefault en 
            <| Dict.get 0 rn.nodes
        )

codeElements : Dict String CodeElementInfo
codeElements = Dict.fromList
    <| List.map (\i -> (i.key, i))
    [ CodeElementInfo "set-to" "Set" 
        "set or create a local variable"
        (TypeList [])
        <| CESetTo
            (ValueInfo VIEmpty AnyType)
            ""
    , CodeElementInfo "math" "Math"
        "compute simple mathematical operation"
        (TypeValue "num")
        <| CEMath
            (ValueInfo VIEmpty <| TypeValue "num")
            MOAdd
            (ValueInfo VIEmpty <| TypeValue "num")
    , CodeElementInfo "compare" "Compare"
        "compare two values"
        (TypeValue "bool")
        <| CECompare
            (ValueInfo VIEmpty <| TypeValue "comparable")
            COEq
            (ValueInfo VIEmpty <| TypeValue "comparable")
    , CodeElementInfo "bool-op" "Boolean Operator"
        "boolean operation"
        (TypeValue "bool")
        <| CEBoolOp
            (ValueInfo (VIValue <| VDBool True) <| TypeValue "bool")
            BOAnd
            (ValueInfo (VIValue <| VDBool False) <| TypeValue "bool")
    , CodeElementInfo "concat" "Concat"
        "concat two values to one string"
        (TypeValue "string")
        <| CEConcat
            (ValueInfo (VIValue <| VDString "") <| TypeValue "concatable")
            (ValueInfo (VIValue <| VDString "") <| TypeValue "concatable")
    , CodeElementInfo "list-get" "Get (List)"
        "get a single value from a list by index"
        (TypeList [ TypeValue "maybe", AnyType ])
        <| CEListGet
            (ValueInfo VIEmpty <| TypeList [ TypeValue "list", AnyType ])
            (ValueInfo VIEmpty <| TypeValue "int")
    , CodeElementInfo "dict-get" "Get (Dict)"
        "get a single value from a dictionary by its key"
        (TypeList [ TypeValue "maybe", AnyType ])
        <| CEDictGet
            (ValueInfo VIEmpty <| TypeList [ TypeValue "dict", AnyType, AnyType ])
            (ValueInfo VIEmpty <| AnyType)
    , CodeElementInfo "tuple-first" "First"
        "returns the first value of a tuple"
        (AnyType)
        <| CETupleFirst
            (ValueInfo VIEmpty <| TypeList [ TypeValue "tuple", AnyType, AnyType ])
    , CodeElementInfo "tuple-second" "Second"
        "returns the second value of a tuple"
        (AnyType)
        <| CETupleSecond
            (ValueInfo VIEmpty <| TypeList [ TypeValue "tuple", AnyType, AnyType ])
    , CodeElementInfo "unwrap-maybe" "Unwrap"
        "unwraps a maybe and execute code if value exists or not"
        (TypeList [])
        <| CEUnwrapMaybe
            (ValueInfo VIEmpty <| TypeList [ TypeValue "maybe", AnyType ])
            ( CodeBlock []
                [ VariableInfo "value" AnyType True ]
                Nothing
            )
            (CodeBlock [] [] Nothing)
    , CodeElementInfo "if" "If"
        "branch depending on a condition"
        (TypeList [])
        <| CEIf
            (ValueInfo (VIValue <| VDBool True)<| TypeValue "bool")
            (CodeBlock [] [] Nothing)
            (CodeBlock [] [] Nothing)
    , CodeElementInfo "for" "For"
        "create a loop with a specific amount of repeatation"
        (TypeList [])
        <| CEFor
            (ValueInfo (VIValue <| VDFloat 0) <| TypeValue "num")
            (ValueInfo (VIValue <| VDFloat 1) <| TypeValue "num")
            (ValueInfo (VIValue <| VDFloat 10) <| TypeValue "num")
            ( CodeBlock []
                [ VariableInfo "i" (TypeValue "num") True ]
                Nothing
            )
    , CodeElementInfo "while" "While"
        "repeat a specific code until the condition is no more fullyfied"
        (TypeList [])
        <| CEWhile
            (ValueInfo (VIValue <| VDBool False) <| TypeValue "bool")
            (CodeBlock [] [] Nothing)
    , CodeElementInfo "break" "Break"
        "breaks the current loop and continue execution after it"
        (TypeList [])
        <| CEBreak
    , CodeElementInfo "foreach-list" "Foreach (List)"
        "execute the code with every item of the list"
        (TypeList [])
        <| CEForeachList
            (ValueInfo VIEmpty <| TypeList [ TypeValue "list", AnyType ])
            ( CodeBlock []
                [ VariableInfo "element" AnyType True ]
                Nothing
            )
    , CodeElementInfo "foreach-dict" "Foreach (Dict)"
        "execute the code with every item of the dictionary"
        (TypeList [])
        <| CEForeachDict
            (ValueInfo VIEmpty <| TypeList [ TypeValue "dict", AnyType, AnyType ])
            ( CodeBlock []
                [ VariableInfo "key" AnyType True
                , VariableInfo "element" AnyType True
                ]
                Nothing
            )
    , CodeElementInfo "end-game" "End Game"
        "Stops the current game (normaly this execution is not required)"
        (TypeList [])
        <| CEEndGame
    , CodeElementInfo "just" "Just"
        "wraps a value in a maybe"
        (TypeList [ TypeValue "maybe", AnyType ])
        <| CEJust
            (ValueInfo VIEmpty <| AnyType)
    , CodeElementInfo "nothing" "Nothing"
        "say there is no value"
        (TypeList [ TypeValue "maybe", AnyType ])
        <| CENothing
    , CodeElementInfo "list" "List"
        "create a new list"
        (TypeList [ TypeValue "list", AnyType ])
        <| CEList 
            [ ValueInfo VIEmpty <| AnyType ]
    , CodeElementInfo "put" "Put"
        "add a item to the end of an existing list"
        (TypeList [])
        <| CEPut ""
            (ValueInfo VIEmpty <| AnyType)
    , CodeElementInfo "get-player" "Get Player"
        "return all Player that have the given roles. If the role filter is nothing, all players would be returned."
        (TypeList [ TypeValue "list", TypeValue "Player" ])
        <| CEGetPlayer
            ( ValueInfo (VIBlock <| CENothing)
                <| TypeList 
                    [ TypeValue "maybe"
                    , TypeList [ TypeValue "list", TypeValue "RoleKey"]
                    ]
            )
            (ValueInfo (VIValue <| VDBool True) 
                (TypeValue "bool")
            )
    , CodeElementInfo "set-room-permission" "Set Room Permission"
        "set the permissions for the given chat room"
        (TypeList [])
        <| CESetRoomPermission
            (ValueInfo (VIValue <| VDChatKey "") <| TypeValue "ChatKey")
            (ValueInfo (VIValue <| VDBool True) <| TypeValue "bool")
            (ValueInfo (VIValue <| VDBool True) <| TypeValue "bool")
            (ValueInfo (VIValue <| VDBool True) <| TypeValue "bool")
    , CodeElementInfo "inform-voting" "Create Voting"
        "create a new voting"
        (TypeList [])
        <| CEInformVoting
            (ValueInfo (VIValue <| VDChatKey "") <| TypeValue "ChatKey")
            (ValueInfo (VIValue <| VDVotingKey "") <| TypeValue "VoteKey")
            (ValueInfo VIEmpty <| TypeList [ TypeValue "list", TypeValue "Player"])
    , CodeElementInfo "add-role-visibility" "Add Role Visibility"
        "make a specific role visible to a specific group of players"
        (TypeList [])
        <| CEAddRoleVisibility
            (ValueInfo VIEmpty <| TypeList [ TypeValue "list", TypeValue "Player" ])
            (ValueInfo VIEmpty <| TypeList [ TypeValue "list", TypeValue "Player" ])
            (ValueInfo 
                (VIBlock
                    <| CEList 
                    <| List.singleton
                    <| ValueInfo 
                        (VIValue <| VDRoleKey "")
                    <| TypeValue "RoleKey"
                ) 
                <| TypeList [ TypeValue "list", TypeValue "RoleKey" ]
            )
    , CodeElementInfo "filter-top-score" "Filter Top Score"
        "filter all players with the highest rank"
        (TypeList [ TypeValue "list", TypeValue "Player"])
        <| CEFilterTopScore
            ( ValueInfo VIEmpty <| TypeList 
                [ TypeValue "list"
                , TypeList 
                    [ TypeValue "tuple"
                    , TypeValue "PlayerId"
                    , TypeValue "int"
                    ]
                ]
            )
    , CodeElementInfo "filter-player" "Filter Player"
        "filter a list of player depending on their roles"
        (TypeList [ TypeValue "list", TypeValue "Player"])
        <| CEFilterPlayer
            (ValueInfo VIEmpty <| TypeList [ TypeValue "list", TypeValue "Player"])
            (ValueInfo 
                (VIBlock
                    <| CEList 
                    <| List.singleton
                    <| ValueInfo 
                        (VIValue <| VDRoleKey "")
                    <| TypeValue "RoleKey"
                ) 
                <| TypeList [ TypeValue "list", TypeValue "RoleKey"]
            )
            (ValueInfo
                (VIBlock
                    <| CEList 
                    <| List.singleton
                    <| ValueInfo 
                        (VIValue <| VDRoleKey "")
                    <| TypeValue "RoleKey"
                ) 
                <| TypeList [ TypeValue "list", TypeValue "RoleKey"]
            )
    , CodeElementInfo "player-id" "Player Id"
        "get the player id of a player object"
        (TypeValue "PlayerId")
        <| CEPlayerId
            (ValueInfo VIEmpty <| TypeValue "Player")
    , CodeElementInfo "player-alive" "Player Alive"
        "returns if the player is currently alive"
        (TypeValue "bool")
        <| CEPlayerAlive
            (ValueInfo VIEmpty <| TypeValue "Player")
    , CodeElementInfo "player-extra-wolf-live" "Player Extra Live"
        "returns if the player has an extra live (for wolves)"
        (TypeValue "bool")
        <| CEPlayerExtraWolfLive
            (ValueInfo VIEmpty <| TypeValue "Player")
    , CodeElementInfo "player-has-role" "Player Has Role"
        "returns if the player has the given role"
        (TypeValue "bool")
        <| CEPlayerHasRole
            (ValueInfo VIEmpty <| TypeValue "Player")
            (ValueInfo (VIValue <| VDRoleKey "") <| TypeValue "RoleKey")
    , CodeElementInfo "player-add-role" "Player Add Role"
        "add a role to a specific player"
        (TypeList [])
        <| CEPlayerAddRole
            (ValueInfo VIEmpty <| TypeValue "Player")
            (ValueInfo (VIValue <| VDRoleKey "") <| TypeValue "RoleKey")
    , CodeElementInfo "player-remove-role" "Player Remove Role"
        "remove a role from a specific player"
        (TypeList [])
        <| CEPlayerRemoveRole
            (ValueInfo VIEmpty <| TypeValue "Player")
            (ValueInfo (VIValue <| VDRoleKey "") <| TypeValue "RoleKey")
    ]

type CodeEditEntry
    = CEEValue String ValueInfo --name value
    | CEEParameter String TypeInfo
    | CEEBlock String CodeBlock --name block
    | CEEMath MathOperator
    | CEECompare CompareOperator
    | CEEBool BoolOperator
    | CEEList CodeEditEntry (List CodeEditEntry) --new_item list

-- only for visual suggar
type CodeCategory
    = CCCalculation
    | CCVariables
    | CCBranches
    | CCUtility

type alias CodeElementEditInfo =
    { key : String
    , category : CodeCategory
    , entrys : List CodeEditEntry
    }

getEditInfo : VarEnvironment -> CodeElement -> CodeElementEditInfo
getEditInfo vars element = case element of 
    CESetTo val par -> CodeElementEditInfo "set-to" CCVariables
        [ CEEValue "input" val
        , CEEParameter par <| getTypeOfValue val.input vars
        ]
    CEMath val1 op val2 -> CodeElementEditInfo "math" CCCalculation
        [ CEEValue "a" val1
        , CEEMath op 
        , CEEValue "b" val2 
        ]
    CECompare val1 op val2 -> CodeElementEditInfo "compare" CCCalculation
        [ CEEValue "a" val1 
        , CEECompare op 
        , CEEValue "b" val2 
        ]
    CEBoolOp val1 op val2 -> CodeElementEditInfo "bool-op" CCCalculation
        [ CEEValue "a" val1 
        , CEEBool op 
        , CEEValue "b" val2 
        ]
    CEConcat val1 val2 -> CodeElementEditInfo "concat" CCCalculation
        [ CEEValue "a" val1
        , CEEValue "b" val2
        ]
    CEListGet val1 val2 -> CodeElementEditInfo "list-get" CCVariables
        [ CEEValue "list" val1
        , CEEValue "index" val2
        ]
    CEDictGet val1 val2 -> CodeElementEditInfo "dict-get" CCVariables
        [ CEEValue "dict" val1
        , CEEValue "key" val2
        ]
    CETupleFirst val -> CodeElementEditInfo "tuple-first" CCVariables
        [ CEEValue "tuple" val 
        ]
    CETupleSecond val -> CodeElementEditInfo "tuple-second" CCVariables
        [ CEEValue "tuple" val 
        ]
    CEUnwrapMaybe val block1 block2 -> CodeElementEditInfo "unwrap-maybe" CCBranches
        [ CEEValue "maybe" val 
        , CEEBlock "just" block1 
        , CEEBlock "nothing" block2 
        ]
    CEIf val block1 block2 -> CodeElementEditInfo "if" CCBranches
        [ CEEValue "condition" val 
        , CEEBlock "then" block1 
        , CEEBlock "else" block2 
        ]
    CEFor val1 val2 val3 block -> CodeElementEditInfo "for" CCBranches
        [ CEEValue "start" val1 
        , CEEValue "step" val2 
        , CEEValue "stop" val3
        , CEEBlock "loop" block
        ]
    CEWhile val block -> CodeElementEditInfo "while" CCBranches
        [ CEEValue "condition" val
        , CEEBlock "loop" block 
        ]
    CEBreak -> CodeElementEditInfo "break" CCBranches []
    CEForeachList val block -> CodeElementEditInfo "foreach-list" CCBranches
        [ CEEValue "list" val 
        , CEEBlock "loop" block 
        ]
    CEForeachDict val block -> CodeElementEditInfo "foreach-dict" CCBranches
        [ CEEValue "dict" val
        , CEEBlock "loop" block 
        ]
    CEEndGame -> CodeElementEditInfo "end-game" CCUtility []
    CEJust val -> CodeElementEditInfo "just" CCVariables
        [ CEEValue "value" val
        ]
    CENothing -> CodeElementEditInfo "nothing" CCVariables []
    CEList list -> CodeElementEditInfo "list" CCVariables
        [ CEEList 
            ( CEEValue "new item"
                { input = VIEmpty
                , desiredType = List.head list 
                    |> Maybe.map (\v -> getTypeOfValue v.input vars)
                    |> Maybe.withDefault AnyType
                }
            )
            <| List.indexedMap 
                (\ind -> CEEValue 
                    <| (++) "value " 
                    <| String.fromInt ind
                )
            <| list
        ]
    CEPut par val -> CodeElementEditInfo "put" CCVariables
        [ CEEParameter par <| TypeList [ TypeValue "list", val.desiredType ]
        , CEEValue "value" val
        ]
    CEGetPlayer val1 val2 -> CodeElementEditInfo "get-player" CCUtility
        [ CEEValue "role" val1 
        , CEEValue "onlyAlive" val2
        ]
    CESetRoomPermission val1 val2 val3 val4 -> CodeElementEditInfo "set-room-permission" CCUtility
        [ CEEValue "room" val1 
        , CEEValue "enable" val2 
        , CEEValue "write" val3
        , CEEValue "visible" val4
        ]
    CEInformVoting val1 val2 val3 -> CodeElementEditInfo "inform-voting" CCUtility
        [ CEEValue "room" val1 
        , CEEValue "name" val2
        , CEEValue "targets" val3
        ]
    CEAddRoleVisibility val1 val2 val3 -> CodeElementEditInfo "add-role-visibility" CCUtility
        [ CEEValue "user" val1 
        , CEEValue "targets" val2
        , CEEValue "roles" val3
        ]
    CEFilterTopScore val -> CodeElementEditInfo "filter-top-score" CCUtility
        [ CEEValue "score" val 
        ]
    CEFilterPlayer val1 val2 val3 -> CodeElementEditInfo "filter-player" CCUtility
        [ CEEValue "players" val1
        , CEEValue "include" val2
        , CEEValue "exclude" val3
        ]
    CEPlayerId val -> CodeElementEditInfo "player-id" CCUtility
        [ CEEValue "player" val
        ]
    CEPlayerAlive val -> CodeElementEditInfo "player-alive" CCUtility
        [ CEEValue "player" val
        ]
    CEPlayerExtraWolfLive val -> CodeElementEditInfo "player-extra-wolf-live" CCUtility
        [ CEEValue "player" val
        ]
    CEPlayerHasRole val1 val2 -> CodeElementEditInfo "player-has-role" CCUtility
        [ CEEValue "player" val1
        , CEEValue "role" val2
        ]
    CEPlayerAddRole val1 val2 -> CodeElementEditInfo "player-add-role" CCUtility
        [ CEEValue "player" val1
        , CEEValue "role" val2
        ]
    CEPlayerRemoveRole val1 val2 -> CodeElementEditInfo "player-remove-role" CCUtility
        [ CEEValue "player" val1
        , CEEValue "role" val2
        ]

pushEdit : Int -> CodeEditEntry -> CodeElement -> CodeElement 
pushEdit index entry element =
    let push : Int 
            -> (CodeEditEntry -> Maybe a) 
            -> a
            -> (a -> b)
            -> b
        push prefered format default return = return
            <| if prefered /= index
                then default
                else Maybe.withDefault default 
                    <| format entry 
        fvalue e = case e of 
            CEEValue _ v -> Just v
            _ -> Nothing
        fparam e = case e of
            CEEParameter v _ -> Just v 
            _ -> Nothing
        fblock e = case e of 
            CEEBlock _ v -> Just v
            _ -> Nothing
        fmath e = case e of 
            CEEMath v -> Just v
            _ -> Nothing
        fcomp e = case e of 
            CEECompare v -> Just v
            _ -> Nothing
        fbool e = case e of 
            CEEBool v -> Just v
            _ -> Nothing
        flist format e = case e of 
            CEEList _ v -> Just 
                <| List.filterMap format v
            _ -> Nothing
    in case element of 
        CESetTo val par -> CESetTo
            |> push 0 fvalue val
            |> push 1 fparam par
        CEMath val1 op val2 -> CEMath
            |> push 0 fvalue val1 
            |> push 1 fmath op 
            |> push 2 fvalue val2
        CECompare val1 op val2 -> CECompare
            |> push 0 fvalue val1
            |> push 1 fcomp op
            |> push 2 fvalue val2
        CEBoolOp val1 op val2 -> CEBoolOp
            |> push 0 fvalue val1
            |> push 1 fbool op 
            |> push 2 fvalue val2
        CEConcat val1 val2 -> CEConcat
            |> push 0 fvalue val1 
            |> push 1 fvalue val2
        CEListGet val1 val2 -> CEListGet
            |> push 0 fvalue val1
            |> push 1 fvalue val2
        CEDictGet val1 val2 -> CEDictGet
            |> push 0 fvalue val1
            |> push 1 fvalue val2
        CETupleFirst val -> CETupleFirst
            |> push 0 fvalue val
        CETupleSecond val -> CETupleSecond
            |> push 0 fvalue val
        CEUnwrapMaybe val block1 block2 -> CEUnwrapMaybe
            |> push 0 fvalue val
            |> push 1 fblock block1
            |> push 2 fblock block2
        CEIf val block1 block2 -> CEIf
            |> push 0 fvalue val
            |> push 1 fblock block1
            |> push 2 fblock block2
        CEFor val1 val2 val3 block -> CEFor
            |> push 0 fvalue val1
            |> push 1 fvalue val2
            |> push 2 fvalue val3
            |> push 3 fblock block
        CEWhile val block -> CEWhile
            |> push 0 fvalue val
            |> push 1 fblock block
        CEBreak -> CEBreak
        CEForeachList val block -> CEForeachList
            |> push 0 fvalue val
            |> push 1 fblock block
        CEForeachDict val block -> CEForeachDict
            |> push 0 fvalue val
            |> push 1 fblock block
        CEEndGame -> CEEndGame
        CEJust val -> CEJust
            |> push 0 fvalue val
        CENothing -> CENothing
        CEList list -> CEList
            |> push 0 (flist fvalue) list
        CEPut par val -> CEPut
            |> push 0 fparam par
            |> push 1 fvalue val
        CEGetPlayer val1 val2 -> CEGetPlayer
            |> push 0 fvalue val1
            |> push 1 fvalue val2
        CESetRoomPermission val1 val2 val3 val4 -> CESetRoomPermission
            |> push 0 fvalue val1
            |> push 1 fvalue val2
            |> push 2 fvalue val3
            |> push 3 fvalue val4
        CEInformVoting val1 val2 val3 -> CEInformVoting
            |> push 0 fvalue val1
            |> push 1 fvalue val2
            |> push 2 fvalue val3
        CEAddRoleVisibility val1 val2 val3 -> CEAddRoleVisibility
            |> push 0 fvalue val1
            |> push 1 fvalue val2
            |> push 2 fvalue val3
        CEFilterTopScore val -> CEFilterTopScore
            |> push 0 fvalue val
        CEFilterPlayer val1 val2 val3 -> CEFilterPlayer
            |> push 0 fvalue val1
            |> push 1 fvalue val2
            |> push 2 fvalue val3
        CEPlayerId val -> CEPlayerId
            |> push 0 fvalue val
        CEPlayerAlive val -> CEPlayerAlive
            |> push 0 fvalue val
        CEPlayerExtraWolfLive val -> CEPlayerExtraWolfLive
            |> push 0 fvalue val
        CEPlayerHasRole val1 val2 -> CEPlayerHasRole
            |> push 0 fvalue val1
            |> push 1 fvalue val2
        CEPlayerAddRole val1 val2 -> CEPlayerAddRole
            |> push 0 fvalue val1
            |> push 1 fvalue val2
        CEPlayerRemoveRole val1 val2 -> CEPlayerRemoveRole
            |> push 0 fvalue val1
            |> push 1 fvalue val2
    
deepEdit : VarEnvironment -> List Int -> CodeEditEntry -> CodeElement -> CodeElement
deepEdit vars path entry root = case path of 
    [] -> root
    i::[] -> pushEdit i entry root
    i::is -> 
        let update : List Int -> CodeEditEntry -> CodeEditEntry
            update spath sentry = 
                if List.isEmpty spath
                then entry 
                else Maybe.withDefault sentry
                    <| case sentry of
                        CEEValue vn v -> case v.input of
                            VIBlock el -> Just
                                <| CEEValue vn
                                    { v 
                                    | input = VIBlock 
                                        <| deepEdit vars 
                                            ( Maybe.withDefault []
                                                <| List.tail spath 
                                            )
                                            entry el 
                                    }
                            _ -> Nothing
                        CEEBlock bn block -> Just <| CEEBlock bn
                            { block
                            | elements = case spath of
                                [] -> block.elements
                                sp::sps -> LE.updateAt 
                                    sp
                                    (deepEdit vars sps entry)
                                    block.elements
                            }
                        CEEList new list -> case spath of
                            [] -> Nothing
                            sp::sps -> Just 
                                <| CEEList new
                                <| LE.updateAt sp 
                                    (update sps)
                                <| list
                        _ -> Nothing
        in getEditInfo vars root
            |> .entrys
            |> LE.getAt i
            |> Maybe.map
                ( update is
                    >> \e -> pushEdit i e root
                )
            |> Maybe.withDefault root

deepGet : VarEnvironment -> List Int -> CodeElement -> Maybe CodeElement
deepGet vars path root = case path of 
    [] -> Just root
    i::is ->
        let searcher : List Int -> CodeEditEntry -> Maybe CodeElement
            searcher spath entry = case entry of 
                CEEValue _ vi -> case vi.input of 
                    VIBlock element -> 
                        deepGet vars 
                            ( Maybe.withDefault []
                                <| List.tail spath
                            ) 
                            element
                    _ -> Nothing
                CEEBlock _ cb -> case spath of 
                    [] -> Nothing 
                    j::js -> Maybe.andThen (deepGet vars js) 
                        <| LE.getAt j cb.elements
                CEEList _ list -> case spath of 
                    [] -> Nothing
                    j::js -> Maybe.andThen (searcher js)
                        <| LE.getAt j list
                _ -> Nothing
        in getEditInfo vars root
            |> .entrys
            |> LE.getAt i
            |> Maybe.andThen (searcher is)
       
deepDelete : VarEnvironment -> List Int -> CodeElement -> Maybe CodeElement
deepDelete vars path root = case path of 
    [] -> Nothing
    i::is ->
        let remover : List Int -> CodeEditEntry -> CodeEditEntry
            remover spath entry = case entry of 
                CEEValue n vi -> case vi.input of 
                    VIBlock element -> case spath of 
                        _::sp -> CEEValue n 
                            { vi 
                            | input = element 
                                |> deepDelete vars sp
                                |> Maybe.map VIBlock
                                |> Maybe.withDefault VIEmpty
                            }
                        _ -> CEEValue n { vi | input = VIEmpty }
                    _ -> CEEValue n { vi | input = VIEmpty }
                CEEBlock n cb -> CEEBlock n 
                    { cb | elements = case spath of 
                        [] -> []
                        j::[] -> LE.removeAt j cb.elements 
                        j::js -> List.map Just cb.elements
                            |> LE.updateAt j 
                                (Maybe.andThen
                                    (deepDelete vars js)
                                )
                            |> List.filterMap identity
                    }
                CEEList new list -> case spath of 
                    [] -> CEEList new []
                    j::[] -> CEEList new <| LE.removeAt j list 
                    j::js -> CEEList new <| LE.updateAt j 
                        (remover js) list
                _ -> entry
        in getEditInfo vars root
            |> .entrys
            |> LE.getAt i
            |> Maybe.map (remover is)
            |> Maybe.map 
                (\e -> pushEdit i e root)
            |> Maybe.withDefault root
            |> Just
        
deepAdd : VarEnvironment -> List Int -> CodeElement -> CodeElement -> CodeElement
deepAdd vars path new root = case path of 
    [] -> new 
    i::is ->
        let insert : Int -> a -> List a -> List a
            insert index element list =
                if index <= 0
                then element :: list 
                else case list of 
                    [] -> [ element ]
                    l::ls -> (::) l <| insert (index - 1) element ls
            adder : List Int -> CodeEditEntry -> CodeEditEntry
            adder spath entry = case entry of 
                CEEValue n vi -> case spath of 
                    [] -> CEEValue n 
                        { vi | input = VIBlock new }
                    j::js -> case vi.input of 
                        VIBlock block -> CEEValue n
                            { vi 
                            | input = VIBlock
                                <| deepAdd vars js new block
                            }
                        _ -> entry
                CEEBlock n cb -> CEEBlock n 
                    { cb | elements = case spath of 
                        [] -> cb.elements ++ [ new ]
                        j::[] -> insert j new cb.elements
                        j::js -> LE.updateAt j
                            (deepAdd vars js new)
                            cb.elements
                    }
                CEEList newItem list -> case spath of 
                    [] -> entry 
                    j::js -> CEEList newItem
                        <| LE.updateAt j (adder js)
                        <| list
                _ -> entry
        in getEditInfo vars root 
            |> .entrys 
            |> LE.getAt i
            |> Maybe.map (adder is)
            |> Maybe.map 
                (\e -> pushEdit i e root)
            |> Maybe.withDefault new 

{-| modify the orign after an injection of newPath in the tree
    newPath: the path of the element that will be injected in the tree
    orign: the path that must be adjusted
-}
injectPath : List Int -> List Int -> List Int
injectPath newPath orign = case newPath of 
    [] -> orign
    p::[] -> case orign of 
        [] -> []
        o::os ->
            ( if p > o then o else o + 1 )
            :: os
    p::ps -> case orign of 
        [] -> []
        o::os ->
            if o == p
            then (::) o <| injectPath ps os
            else orign

{-| modify the orign after an removement of oldPath from the tree
    oldPath: the path of the element that will be removed from the tree
    orign: the path that must be adjusted
-}
removePath : List Int -> List Int -> List Int 
removePath oldPath orign = case oldPath of 
    [] -> orign
    p::[] -> case orign of 
        [] -> []
        o::os ->
            ( if p > o then o else o - 1 )
            :: os
    p::ps -> case orign of 
        [] -> []
        o::os ->
            if o == p 
            then (::) o <| removePath ps os 
            else orign

isPrefix : List Int -> List Int -> Bool 
isPrefix prefix path = case (prefix, path) of 
    ([], []) -> True 
    (p::_, []) -> False 
    ([], o::_) -> True 
    (p::ps, o::os) ->   
        if p == o 
        then isPrefix ps os 
        else False

preview : CodeElement -> String 
preview element = 
    let maxLevel = 10
        maxChars = 120
        maxStringLength = 30

        stopIf : Int -> (() -> String) -> String 
        stopIf level callback =
            if level >= maxLevel
            then "(..)"
            else callback ()

        previewValue : ValueInfo -> Int -> String 
        previewValue value level = stopIf level <| \() ->
            case value.input of 
                VIEmpty -> "null"
                VIValue (VDInt n) -> String.fromInt n
                VIValue (VDFloat n) -> String.fromFloat n
                VIValue (VDString s) -> "\"" ++ 
                    (s 
                        |> String.replace "\n" "\\n"
                        |> String.replace "\"" "\\\""
                        |> String.replace "\t" "\\t"
                        |> String.replace "\r" "\\r"
                        |> \rs ->
                            if String.length rs > maxStringLength
                            then String.left (maxStringLength - 3) rs
                                ++ "..."
                            else rs
                    ) 
                    ++ "\""
                VIValue (VDBool True) -> "true"
                VIValue (VDBool False) -> "false"
                VIValue (VDRoleKey s) -> "\"" ++ s ++ "\""
                VIValue (VDPhaseKey s) -> "\"" ++ s ++ "\""
                VIValue (VDChatKey s) -> "\"" ++ s ++ "\""
                VIValue (VDVotingKey s) -> "\"" ++ s ++ "\""
                VIVariable s -> "$" ++ s 
                VIBlock b -> String.concat 
                    [ "("
                    , previewElement b <| level + 1
                    , ")"
                    ]

        previewElement : CodeElement -> Int -> String 
        previewElement elem level = stopIf level <| \() ->  
            String.concat <| case elem of 
                CESetTo val par -> 
                    [ "$" 
                    , par 
                    , " = "
                    , previewValue val <| level + 1
                    ]
                CEMath val1 op val2 ->
                    [ previewValue val1 <| level + 1
                    , case op of 
                        MOAdd -> " + "
                        MOSub -> " - "
                        MOMul -> " * "
                        MODiv -> " / "
                    , previewValue val2 <| level + 1
                    ]
                CECompare val1 op val2 ->
                    [ previewValue val1 <| level + 1
                    , case op of 
                        COEq -> " == "
                        CONeq -> " != "
                        COLt -> " < "
                        COLtEq -> " <= "
                        COGt -> " > "
                        COGtEq -> " >= "
                    , previewValue val2 <| level + 1
                    ]
                CEBoolOp val1 op val2 ->
                    [ previewValue val1 <| level + 1
                    , case op of 
                        BOAnd -> " and "
                        BOOr -> " or "
                        BOXor -> " xor "
                        BONand -> " nand "
                        BOXnor -> " xnor "
                        BONor -> " nor "
                    , previewValue val2 <| level + 1
                    ]
                CEConcat val1 val2 ->
                    [ previewValue val1 <| level + 1
                    , " ++ "
                    , previewValue val2 <| level + 1
                    ]
                CEListGet val1 val2 ->
                    [ previewValue val1 <| level + 1
                    , "["
                    , previewValue val2 <| level + 1
                    , "]"
                    ]
                CEDictGet val1 val2 ->
                    [ previewValue val1 <| level + 1
                    , "["
                    , previewValue val2 <| level + 1
                    , "]"
                    ]
                CETupleFirst val ->
                    [ "first("
                    , previewValue val <| level + 1
                    , ")"
                    ]
                CETupleSecond val ->
                    [ "second("
                    , previewValue val <| level + 1
                    , ")"
                    ]
                CEUnwrapMaybe val block1 block2 ->
                    [ "unwrap("
                    , previewValue val <| level + 1
                    , ", "
                    , previewBlock block1 <| level + 1
                    , ", "
                    , previewBlock block2 <| level + 1
                    , ")"
                    ]
                CEIf val block1 block2 ->
                    [ "if ("
                    , previewValue val <| level + 1
                    , ") "
                    , previewBlock block1 <| level + 1
                    , " else "
                    , previewBlock block2 <| level + 1
                    ]
                CEFor val1 val2 val3 block ->
                    [ "for ($"
                    , List.head block.vars
                        |> Maybe.map .key
                        |> Maybe.withDefault "i"
                    , "="
                    , previewValue val1 <| level + 1
                    , "; "
                    , List.head block.vars
                        |> Maybe.map .key
                        |> Maybe.withDefault "i"
                    , "<="
                    , previewValue val3 <| level + 1
                    , "; "
                    , List.head block.vars
                        |> Maybe.map .key
                        |> Maybe.withDefault "i"
                    , "+="
                    , previewValue val2 <| level + 1
                    , ") "
                    , previewBlock block <| level + 1
                    ]
                CEWhile val block ->
                    [ "while ("
                    , previewValue val <| level + 1
                    , ") "
                    , previewBlock block <| level + 1
                    ]
                CEBreak ->
                    [ "break" ]
                CEForeachList val block ->
                    [ "foreach ("
                    , previewValue val <| level + 1
                    , " as $"
                    , LE.getAt 0 block.vars
                        |> Maybe.map .key
                        |> Maybe.withDefault "value"
                    , ") "
                    , previewBlock block <| level + 1
                    ]
                CEForeachDict val block ->
                    [ "foreach ("
                    , previewValue val <| level + 1
                    , " as $"
                    , LE.getAt 0 block.vars
                        |> Maybe.map .key
                        |> Maybe.withDefault "key"
                    , " => $"
                    , LE.getAt 0 block.vars
                        |> Maybe.map .key
                        |> Maybe.withDefault "value"
                    , ") "
                    , previewBlock block <| level + 1
                    ]
                CEEndGame -> 
                    [ "endGame()" ]
                CEJust val ->
                    [ "just("
                    , previewValue val <| level + 1
                    , ")"
                    ]
                CENothing ->
                    [ "nothing()" ]
                CEList list ->
                    [ previewList 
                        previewValue
                        "[ "
                        " ]"
                        ", "
                        list
                        <| level + 1
                    ]
                CEPut param val ->
                    [ "$"
                    , param
                    , " []= "
                    , previewValue val <| level + 1
                    ]
                CEGetPlayer val1 val2 ->
                    [ "getPlayer("
                    , previewValue val1 <| level + 1
                    , ", "
                    , previewValue val2 <| level + 1
                    , ")"
                    ]
                CESetRoomPermission val1 val2 val3 val4 ->
                    [ "setRoomPermission("
                    , previewValue val1 <| level + 1
                    , ", "
                    , previewValue val2 <| level + 1
                    , ", "
                    , previewValue val3 <| level + 1
                    , ", "
                    , previewValue val4 <| level + 1
                    , ")"
                    ]
                CEInformVoting val1 val2 val3 ->
                    [ "informVoting("
                    , previewValue val1 <| level + 1
                    , ", "
                    , previewValue val2 <| level + 1
                    , ", "
                    , previewValue val3 <| level + 1
                    , ")"
                    ]
                CEAddRoleVisibility val1 val2 val3 ->
                    [ "addRoleVisibility("
                    , previewValue val1 <| level + 1
                    , ", "
                    , previewValue val2 <| level + 1
                    , ", "
                    , previewValue val3 <| level + 1
                    , ")"
                    ]
                CEFilterTopScore val ->
                    [ "filterTopScore("
                    , previewValue val <| level + 1
                    , ")"
                    ]
                CEFilterPlayer val1 val2 val3 ->
                    [ "filterPlayer("
                    , previewValue val1 <| level + 1
                    , ", "
                    , previewValue val2 <| level + 1
                    , ", "
                    , previewValue val3 <| level + 1
                    , ")"
                    ]
                CEPlayerId val ->
                    [ previewValue val <| level + 1
                    , "->id"
                    ]
                CEPlayerAlive val ->
                    [ previewValue val <| level + 1
                    , "->alive"
                    ]
                CEPlayerExtraWolfLive val ->
                    [ previewValue val <| level + 1
                    , "->extraWolfLive"
                    ]
                CEPlayerHasRole val1 val2 ->
                    [ previewValue val1 <| level + 1
                    , "->hasRole("
                    , previewValue val2 <| level + 1
                    , ")"
                    ]
                CEPlayerAddRole val1 val2 ->
                    [ previewValue val1 <| level + 1
                    , "->addRole("
                    , previewValue val2 <| level + 1
                    , ")"
                    ]
                CEPlayerRemoveRole val1 val2 ->
                    [ previewValue val1 <| level + 1
                    , "->removeRole("
                    , previewValue val2 <| level + 1
                    , ")"
                    ]

        previewBlock : CodeBlock -> Int -> String 
        previewBlock block level = stopIf level <| \() ->
            previewList
                previewElement 
                "{ "
                " }"
                "; "
                block.elements
                level

        previewList : (a -> Int -> String) -> String -> String -> String -> List a -> Int -> String 
        previewList func left right separator list level = String.concat
            <| List.concat
            [ [ left ]
            , List.take 3 list 
                |>  (\sl -> List.filterMap identity
                        [ List.take 2 sl
                            |> List.map (\a -> func a <| level + 1)
                            |> List.intersperse separator
                            |> String.concat
                            |> Just
                        , if List.length sl == 3
                            then Just <| separator ++ "..."
                            else Nothing
                        ]
                    )
            , [ right ]
            ]
    
        tryLongText : Int -> String 
        tryLongText level = previewElement element level 
            |> \lt ->
                if String.length lt <= maxChars ||
                    level == maxLevel
                then lt 
                else tryLongText <| level + 1
    in tryLongText 0

type alias CodeEnvironment =
    { blocks : Dict String CodeEnvironmentBlockType
    , clipboard : List CodeBlock
    }

type CodeEnvironmentBlockType 
    = CEBTDirect CodeBlock
    | CEBTPhased CodeBlock (Dict String CodeBlock)
    | CEBTRoled CodeBlock (Dict String CodeBlock)
    | CEBTRoomName CodeBlock (Dict (String, String) CodeBlock)

newCodeEnvironment : CodeEnvironment
newCodeEnvironment =
    { blocks = Dict.fromList 
        [ Tuple.pair "onStartRound"
            <| CEBTPhased 
                { elements = []
                , vars = 
                    [ VariableInfo "round"
                        (TypeValue "int")
                        True
                    ]
                , return = Nothing
                }
            <| Dict.empty 
        , Tuple.pair "onLeaveRound"
            <| CEBTPhased 
                { elements = []
                , vars = 
                    [ VariableInfo "round"
                        (TypeValue "int")
                        True
                    ]
                , return = Nothing
                }
            <| Dict.empty 
        , Tuple.pair "needToExecuteRound"
            <| CEBTPhased 
                { elements = 
                    [ CESetTo 
                        { input = VIValue <| VDBool False
                        , desiredType = TypeValue "bool"
                        }
                        "return"
                    ]
                , vars = 
                    [ VariableInfo "round"
                        (TypeValue "int")
                        True
                    ]
                , return = Just 
                    <| VariableInfo "return"
                        (TypeValue "bool")
                        True
                }
            <| Dict.empty 
        , Tuple.pair "isWinner"
            <| CEBTRoled 
                { elements = 
                    [ CESetTo 
                        { input = VIValue <| VDBool False
                        , desiredType = TypeValue "bool"
                        }
                        "return"
                    ]
                , vars = 
                    [ VariableInfo "caller"
                        (TypeValue "Player")
                        True
                    ]
                , return = Just 
                    <| VariableInfo "return"
                        (TypeValue "bool")
                        True
                }
            <| Dict.empty 
        , Tuple.pair "canVote"
            <| CEBTRoomName 
                { elements = 
                    [ CESetTo 
                        { input = VIValue <| VDBool False
                        , desiredType = TypeValue "bool"
                        }
                        "return"
                    ]
                , vars = []
                , return = Just 
                    <| VariableInfo "return"
                        (TypeValue "bool")
                        True
                }
            <| Dict.empty 
        , Tuple.pair "onVotingCreated"
            <| CEBTRoomName
                { elements = []
                , vars = []
                , return = Nothing
                }
            <| Dict.empty 
        , Tuple.pair "onVotingStarts"
            <| CEBTRoomName 
                { elements = []
                , vars = []
                , return = Nothing
                }
            <| Dict.empty 
        , Tuple.pair "onVotingStops"
            <| CEBTRoomName 
                { elements = []
                , vars = 
                    [ VariableInfo "result"
                        ( TypeList 
                            [ TypeValue "list"
                            , TypeList 
                                [ TypeValue "tuple"
                                , TypeValue "PlayerId"
                                , TypeValue "int"
                                ]
                            ]
                        )
                        True
                    , VariableInfo "voter"
                        ( TypeList 
                            [ TypeValue "dict"
                            , TypeValue "PlayerId"
                            , TypeList 
                                [ TypeValue "list"
                                , TypeValue "PlayerId"
                                ]
                            ]
                        )
                        True
                    ]
                , return = Nothing
                }
            <| Dict.empty 
        , Tuple.pair "onGameStarts"
            <| CEBTDirect 
                { elements = []
                , vars = 
                    [ VariableInfo "round"
                        (TypeValue "int")
                        True
                    , VariableInfo "phase"
                        (TypeValue "PhaseKey")
                        True
                    ]
                , return = Nothing
                }
        , Tuple.pair "onGameEnds"
            <| CEBTDirect 
                { elements = []
                , vars =
                    [ VariableInfo "round"
                        (TypeValue "int")
                        True
                    , VariableInfo "phase"
                        (TypeValue "PhaseKey")
                        True
                    , VariableInfo "teams"
                        (TypeList [ TypeValue "list", TypeValue "RoleKey"])
                        True 
                    ]
                , return = Nothing
                }
        ]
    , clipboard = List.singleton
        { elements = []
        , vars = []
        , return = Nothing
        }
    }

type CodeEnvironmentPath path 
    = CEPBlocks (List String) path
    | CEPClipboard Int path

getCEPath : CodeEnvironmentPath path -> path 
getCEPath epath = case epath of 
    CEPBlocks _ p -> p 
    CEPClipboard _ p -> p

setCEPath : path1 -> CodeEnvironmentPath path2 -> CodeEnvironmentPath path1 
setCEPath newPath epath = case epath of 
    CEPBlocks rp _ -> CEPBlocks rp newPath
    CEPClipboard rp _ -> CEPClipboard rp newPath

getCEBlock : CodeEnvironmentPath path -> (Maybe (List String), Maybe Int)
getCEBlock epath = case epath of
    CEPBlocks rp _ -> (Just rp, Nothing)
    CEPClipboard rp _ -> (Nothing, Just rp)

mapCodeEnvironment : (path -> CodeBlock -> CodeBlock) 
    -> CodeEnvironmentPath path 
    -> CodeEnvironment
    -> CodeEnvironment
mapCodeEnvironment mapFunc epath env = case epath of
    CEPBlocks [] subPath -> env
    CEPBlocks (method::dictAccess) subPath ->
        { env 
        | blocks = Dict.update method 
            (Maybe.map
                (\cebt -> case (cebt, dictAccess) of 
                    (CEBTDirect block, _) -> CEBTDirect
                        <| mapFunc subPath block 
                    (CEBTPhased n d, p::_) -> CEBTPhased n 
                        <| Dict.update p
                            (Maybe.map (mapFunc subPath))
                            d
                    (CEBTRoled n d, p::_) -> CEBTRoled n 
                        <| Dict.update p
                            (Maybe.map (mapFunc subPath))
                            d
                    (CEBTRoomName n d, p1::p2::_) -> CEBTRoomName n
                        <| Dict.update (p1, p2)
                            (Maybe.map (mapFunc subPath))
                            d
                    _ -> cebt
                )
            )
            env.blocks
        }
    CEPClipboard index subPath ->
        { env 
        | clipboard = LE.updateAt index 
            (mapFunc subPath)
            env.clipboard
        }

createPathList : Bool -> Bool -> (CodeBlock -> a) -> CodeEnvironment -> List (CodeEnvironmentPath a)
createPathList inclBlocks inclClipboard mapper environment =
    List.concat 
        [ if inclBlocks
            then environment.blocks
                |> Dict.toList
                |> List.concatMap 
                    (\(k, bt) -> case bt of 
                        CEBTDirect b -> [ CEPBlocks [k] <| mapper b ]
                        CEBTPhased _ d -> Dict.toList d 
                            |> List.map 
                                (\(p, b) -> CEPBlocks [k,p] <| mapper b)
                        CEBTRoled _ d -> Dict.toList d 
                            |> List.map 
                                (\(p, b) -> CEPBlocks [k,p] <| mapper b)
                        CEBTRoomName _ d -> Dict.toList d 
                            |> List.map 
                                (\((p1,p2),b) -> CEPBlocks [k,p1,p2] <| mapper b)
                    )
            else []
        , if inclClipboard 
            then environment.clipboard 
                |> List.indexedMap
                    (\ind -> CEPClipboard ind << mapper)
            else []
        ]

addEmptyCodeEnvironment : String 
    -> List String 
    -> CodeEnvironment
    -> CodeEnvironment
addEmptyCodeEnvironment method dictAccess env =
    { env 
    | blocks = Dict.update method
        (Maybe.map 
            (\e -> case e of 
                CEBTDirect cb -> CEBTDirect cb
                CEBTPhased new d -> CEBTPhased new 
                    <| case dictAccess of 
                        k::_ -> Dict.insert k new d 
                        _ -> d
                CEBTRoled new d -> CEBTRoled new 
                    <| case dictAccess of 
                        k::_ -> Dict.insert k new d 
                        _ -> d 
                CEBTRoomName new d -> CEBTRoomName new 
                    <| case dictAccess of 
                        k1::k2::_ -> Dict.insert (k1,k2) new d 
                        _ -> d
            )
        )
        env.blocks
    }

addClipboard : CodeEnvironment -> CodeEnvironment
addClipboard env =
    { env 
    | clipboard = (++) env.clipboard
        <| List.singleton
        <|  { elements = []
            , vars = []
            , return = Nothing
            }
    }

removeRootCodeBlock : CodeEnvironmentPath () -> CodeEnvironment -> CodeEnvironment
removeRootCodeBlock path environment = case path of 
    CEPBlocks (name::spath) () -> 
        { environment
        | blocks = Dict.update name 
            (Maybe.map 
                (\ceb -> case (ceb, spath) of 
                    (CEBTDirect cb, _) -> CEBTDirect 
                        { cb 
                        | elements = []
                        }
                    (CEBTPhased new dict, p::_) -> CEBTPhased new 
                        <| Dict.remove p dict 
                    (CEBTRoled new dict, p::_) -> CEBTRoled new 
                        <| Dict.remove p dict 
                    (CEBTRoomName new dict, p1::p2::_) -> CEBTRoomName new 
                        <| Dict.remove (p1,p2) dict 
                    _ -> ceb
                )
            )
            environment.blocks
        }
    CEPClipboard index () ->
        { environment 
        | clipboard = LE.removeAt index environment.clipboard
        }
    _ -> environment
