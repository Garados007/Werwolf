module Dashboard.Editor.Logic.Converter exposing
    ( decodeBoolOperator
    , decodeCodeBlock
    , decodeCodeCategory
    , decodeCodeEditEntry
    , decodeCodeElement
    , decodeCodeElementEditInfo
    , decodeCodeElementInfo
    , decodeCodeEnvironment
    , decodeCodeEnvironmentBlockType
    , decodeCodeEnvironmentPath
    , decodeCompareOperator
    , decodeErrorNode
    , decodeMathOperator
    , decodeTypeInfo
    , decodeValueDirect
    , decodeValueInfo
    , decodeValueInput
    , decodeVarDefinition
    , decodeVarEnvironment
    , decodeVariableInfo
    , encodeBoolOperator
    , encodeCodeBlock
    , encodeCodeCategory
    , encodeCodeEditEntry
    , encodeCodeElement
    , encodeCodeElementEditInfo
    , encodeCodeElementInfo
    , encodeCodeEnvironment
    , encodeCodeEnvironmentBlockType
    , encodeCodeEnvironmentPath
    , encodeCompareOperator
    , encodeErrorNode
    , encodeMathOperator
    , encodeTypeInfo
    , encodeValueDirect
    , encodeValueInfo
    , encodeValueInput
    , encodeVarDefinition
    , encodeVarEnvironment
    , encodeVariableInfo
    )

-- required imports

import Dict
import Json.Decode
import Json.Decode.Pipeline
import Json.Encode
import Result exposing (Result (..))
import Set
import Tuple

-- module import

import Dashboard.Editor.Logic exposing
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
    )

-- converter

encodeTypeInfo : TypeInfo -> Json.Encode.Value
encodeTypeInfo =
    (\v_0 -> case v_0 of
        AnyType -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "AnyType"
            ]
        TypeValue v_0_0 -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "TypeValue"
            , Tuple.pair "0"
                <| Json.Encode.string
                    v_0_0
            ]
        TypeList v_0_0 -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "TypeList"
            , Tuple.pair "0"
                <| ( Json.Encode.list
                        encodeTypeInfo
                    )
                    v_0_0
            ]
    )

decodeTypeInfo : Json.Decode.Decoder TypeInfo
decodeTypeInfo =
    Json.Decode.field "type" Json.Decode.string
        |> Json.Decode.andThen
        (\v_0 -> case v_0 of
            "AnyType" -> Json.Decode.succeed AnyType
            "TypeValue" -> Json.Decode.succeed TypeValue
                |> Json.Decode.Pipeline.required "0"
                    ( Json.Decode.string
                    )
            "TypeList" -> Json.Decode.succeed TypeList
                |> Json.Decode.Pipeline.required "0"
                    ( Json.Decode.list
                        ( decodeTypeInfo
                        )
                    )
            _ -> Json.Decode.fail <| "no representation of variant " ++ v_0 ++ " found"
        )

encodeVariableInfo : VariableInfo -> Json.Encode.Value
encodeVariableInfo =
    (\g_0 -> Json.Encode.object
        [ Tuple.pair "key"
            <| Json.Encode.string
                g_0.key
        , Tuple.pair "type_"
            <| encodeTypeInfo
                g_0.type_
        , Tuple.pair "readonly"
            <| Json.Encode.bool
                g_0.readonly
        ]
    )

decodeVariableInfo : Json.Decode.Decoder VariableInfo
decodeVariableInfo =
    Json.Decode.succeed
        (\g_0_key g_0_type_ g_0_readonly ->
            { key = g_0_key
            , type_ = g_0_type_
            , readonly = g_0_readonly
            }
        )
        |> Json.Decode.Pipeline.required "key"
            ( Json.Decode.string
            )
        |> Json.Decode.Pipeline.required "type_"
            ( decodeTypeInfo
            )
        |> Json.Decode.Pipeline.required "readonly"
            ( Json.Decode.bool
            )

encodeValueInfo : ValueInfo -> Json.Encode.Value
encodeValueInfo =
    (\g_1 -> Json.Encode.object
        [ Tuple.pair "input"
            <| encodeValueInput
                g_1.input
        , Tuple.pair "desiredType"
            <| encodeTypeInfo
                g_1.desiredType
        ]
    )

decodeValueInfo : Json.Decode.Decoder ValueInfo
decodeValueInfo =
    Json.Decode.succeed
        (\g_1_input g_1_desiredType ->
            { input = g_1_input
            , desiredType = g_1_desiredType
            }
        )
        |> Json.Decode.Pipeline.required "input"
            ( decodeValueInput
            )
        |> Json.Decode.Pipeline.required "desiredType"
            ( decodeTypeInfo
            )

encodeValueInput : ValueInput -> Json.Encode.Value
encodeValueInput =
    (\v_1 -> case v_1 of
        VIEmpty -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "VIEmpty"
            ]
        VIValue v_1_0 -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "VIValue"
            , Tuple.pair "0"
                <| encodeValueDirect
                    v_1_0
            ]
        VIVariable v_1_0 -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "VIVariable"
            , Tuple.pair "0"
                <| Json.Encode.string
                    v_1_0
            ]
        VIBlock v_1_0 -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "VIBlock"
            , Tuple.pair "0"
                <| encodeCodeElement
                    v_1_0
            ]
    )

decodeValueInput : Json.Decode.Decoder ValueInput
decodeValueInput =
    Json.Decode.field "type" Json.Decode.string
        |> Json.Decode.andThen
        (\v_1 -> case v_1 of
            "VIEmpty" -> Json.Decode.succeed VIEmpty
            "VIValue" -> Json.Decode.succeed VIValue
                |> Json.Decode.Pipeline.required "0"
                    ( decodeValueDirect
                    )
            "VIVariable" -> Json.Decode.succeed VIVariable
                |> Json.Decode.Pipeline.required "0"
                    ( Json.Decode.string
                    )
            "VIBlock" -> Json.Decode.succeed VIBlock
                |> Json.Decode.Pipeline.required "0"
                    ( decodeCodeElement
                    )
            _ -> Json.Decode.fail <| "no representation of variant " ++ v_1 ++ " found"
        )

encodeValueDirect : ValueDirect -> Json.Encode.Value
encodeValueDirect =
    (\v_2 -> case v_2 of
        VDInt v_2_0 -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "VDInt"
            , Tuple.pair "0"
                <| Json.Encode.int
                    v_2_0
            ]
        VDFloat v_2_0 -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "VDFloat"
            , Tuple.pair "0"
                <| Json.Encode.float
                    v_2_0
            ]
        VDString v_2_0 -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "VDString"
            , Tuple.pair "0"
                <| Json.Encode.string
                    v_2_0
            ]
        VDBool v_2_0 -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "VDBool"
            , Tuple.pair "0"
                <| Json.Encode.bool
                    v_2_0
            ]
        VDRoleKey v_2_0 -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "VDRoleKey"
            , Tuple.pair "0"
                <| Json.Encode.string
                    v_2_0
            ]
        VDPhaseKey v_2_0 -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "VDPhaseKey"
            , Tuple.pair "0"
                <| Json.Encode.string
                    v_2_0
            ]
        VDChatKey v_2_0 -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "VDChatKey"
            , Tuple.pair "0"
                <| Json.Encode.string
                    v_2_0
            ]
        VDVotingKey v_2_0 -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "VDVotingKey"
            , Tuple.pair "0"
                <| Json.Encode.string
                    v_2_0
            ]
    )

decodeValueDirect : Json.Decode.Decoder ValueDirect
decodeValueDirect =
    Json.Decode.field "type" Json.Decode.string
        |> Json.Decode.andThen
        (\v_2 -> case v_2 of
            "VDInt" -> Json.Decode.succeed VDInt
                |> Json.Decode.Pipeline.required "0"
                    ( Json.Decode.int
                    )
            "VDFloat" -> Json.Decode.succeed VDFloat
                |> Json.Decode.Pipeline.required "0"
                    ( Json.Decode.float
                    )
            "VDString" -> Json.Decode.succeed VDString
                |> Json.Decode.Pipeline.required "0"
                    ( Json.Decode.string
                    )
            "VDBool" -> Json.Decode.succeed VDBool
                |> Json.Decode.Pipeline.required "0"
                    ( Json.Decode.bool
                    )
            "VDRoleKey" -> Json.Decode.succeed VDRoleKey
                |> Json.Decode.Pipeline.required "0"
                    ( Json.Decode.string
                    )
            "VDPhaseKey" -> Json.Decode.succeed VDPhaseKey
                |> Json.Decode.Pipeline.required "0"
                    ( Json.Decode.string
                    )
            "VDChatKey" -> Json.Decode.succeed VDChatKey
                |> Json.Decode.Pipeline.required "0"
                    ( Json.Decode.string
                    )
            "VDVotingKey" -> Json.Decode.succeed VDVotingKey
                |> Json.Decode.Pipeline.required "0"
                    ( Json.Decode.string
                    )
            _ -> Json.Decode.fail <| "no representation of variant " ++ v_2 ++ " found"
        )

encodeCodeBlock : CodeBlock -> Json.Encode.Value
encodeCodeBlock =
    (\g_2 -> Json.Encode.object
        [ Tuple.pair "elements"
            <| ( Json.Encode.list
                    encodeCodeElement
                )
                g_2.elements
        , Tuple.pair "vars"
            <| ( Json.Encode.list
                    encodeVariableInfo
                )
                g_2.vars
        , Tuple.pair "return"
            <| (\m_0 -> case m_0 of
                    Nothing -> Json.Encode.null
                    Just m_0_j -> encodeVariableInfo
                        m_0_j
                )
                g_2.return
        ]
    )

decodeCodeBlock : Json.Decode.Decoder CodeBlock
decodeCodeBlock =
    Json.Decode.succeed
        (\g_2_elements g_2_vars g_2_return ->
            { elements = g_2_elements
            , vars = g_2_vars
            , return = g_2_return
            }
        )
        |> Json.Decode.Pipeline.required "elements"
            ( Json.Decode.list
                ( decodeCodeElement
                )
            )
        |> Json.Decode.Pipeline.required "vars"
            ( Json.Decode.list
                ( decodeVariableInfo
                )
            )
        |> Json.Decode.Pipeline.required "return"
            ( Json.Decode.maybe
                ( decodeVariableInfo
                )
            )

encodeMathOperator : MathOperator -> Json.Encode.Value
encodeMathOperator =
    (\v_3 -> case v_3 of
        MOAdd -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "MOAdd"
            ]
        MOSub -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "MOSub"
            ]
        MOMul -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "MOMul"
            ]
        MODiv -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "MODiv"
            ]
    )

decodeMathOperator : Json.Decode.Decoder MathOperator
decodeMathOperator =
    Json.Decode.field "type" Json.Decode.string
        |> Json.Decode.andThen
        (\v_3 -> case v_3 of
            "MOAdd" -> Json.Decode.succeed MOAdd
            "MOSub" -> Json.Decode.succeed MOSub
            "MOMul" -> Json.Decode.succeed MOMul
            "MODiv" -> Json.Decode.succeed MODiv
            _ -> Json.Decode.fail <| "no representation of variant " ++ v_3 ++ " found"
        )

encodeCompareOperator : CompareOperator -> Json.Encode.Value
encodeCompareOperator =
    (\v_4 -> case v_4 of
        COEq -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "COEq"
            ]
        CONeq -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "CONeq"
            ]
        COLt -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "COLt"
            ]
        COLtEq -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "COLtEq"
            ]
        COGt -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "COGt"
            ]
        COGtEq -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "COGtEq"
            ]
    )

decodeCompareOperator : Json.Decode.Decoder CompareOperator
decodeCompareOperator =
    Json.Decode.field "type" Json.Decode.string
        |> Json.Decode.andThen
        (\v_4 -> case v_4 of
            "COEq" -> Json.Decode.succeed COEq
            "CONeq" -> Json.Decode.succeed CONeq
            "COLt" -> Json.Decode.succeed COLt
            "COLtEq" -> Json.Decode.succeed COLtEq
            "COGt" -> Json.Decode.succeed COGt
            "COGtEq" -> Json.Decode.succeed COGtEq
            _ -> Json.Decode.fail <| "no representation of variant " ++ v_4 ++ " found"
        )

encodeBoolOperator : BoolOperator -> Json.Encode.Value
encodeBoolOperator =
    (\v_5 -> case v_5 of
        BOAnd -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "BOAnd"
            ]
        BOOr -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "BOOr"
            ]
        BOXor -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "BOXor"
            ]
        BONand -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "BONand"
            ]
        BOXnor -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "BOXnor"
            ]
        BONor -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "BONor"
            ]
    )

decodeBoolOperator : Json.Decode.Decoder BoolOperator
decodeBoolOperator =
    Json.Decode.field "type" Json.Decode.string
        |> Json.Decode.andThen
        (\v_5 -> case v_5 of
            "BOAnd" -> Json.Decode.succeed BOAnd
            "BOOr" -> Json.Decode.succeed BOOr
            "BOXor" -> Json.Decode.succeed BOXor
            "BONand" -> Json.Decode.succeed BONand
            "BOXnor" -> Json.Decode.succeed BOXnor
            "BONor" -> Json.Decode.succeed BONor
            _ -> Json.Decode.fail <| "no representation of variant " ++ v_5 ++ " found"
        )

encodeCodeElement : CodeElement -> Json.Encode.Value
encodeCodeElement =
    (\v_6 -> case v_6 of
        CESetTo v_6_0 v_6_1 -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "CESetTo"
            , Tuple.pair "0"
                <| encodeValueInfo
                    v_6_0
            , Tuple.pair "1"
                <| Json.Encode.string
                    v_6_1
            ]
        CEMath v_6_0 v_6_1 v_6_2 -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "CEMath"
            , Tuple.pair "0"
                <| encodeValueInfo
                    v_6_0
            , Tuple.pair "1"
                <| encodeMathOperator
                    v_6_1
            , Tuple.pair "2"
                <| encodeValueInfo
                    v_6_2
            ]
        CECompare v_6_0 v_6_1 v_6_2 -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "CECompare"
            , Tuple.pair "0"
                <| encodeValueInfo
                    v_6_0
            , Tuple.pair "1"
                <| encodeCompareOperator
                    v_6_1
            , Tuple.pair "2"
                <| encodeValueInfo
                    v_6_2
            ]
        CEBoolOp v_6_0 v_6_1 v_6_2 -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "CEBoolOp"
            , Tuple.pair "0"
                <| encodeValueInfo
                    v_6_0
            , Tuple.pair "1"
                <| encodeBoolOperator
                    v_6_1
            , Tuple.pair "2"
                <| encodeValueInfo
                    v_6_2
            ]
        CEConcat v_6_0 v_6_1 -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "CEConcat"
            , Tuple.pair "0"
                <| encodeValueInfo
                    v_6_0
            , Tuple.pair "1"
                <| encodeValueInfo
                    v_6_1
            ]
        CEListGet v_6_0 v_6_1 -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "CEListGet"
            , Tuple.pair "0"
                <| encodeValueInfo
                    v_6_0
            , Tuple.pair "1"
                <| encodeValueInfo
                    v_6_1
            ]
        CEDictGet v_6_0 v_6_1 -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "CEDictGet"
            , Tuple.pair "0"
                <| encodeValueInfo
                    v_6_0
            , Tuple.pair "1"
                <| encodeValueInfo
                    v_6_1
            ]
        CETupleFirst v_6_0 -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "CETupleFirst"
            , Tuple.pair "0"
                <| encodeValueInfo
                    v_6_0
            ]
        CETupleSecond v_6_0 -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "CETupleSecond"
            , Tuple.pair "0"
                <| encodeValueInfo
                    v_6_0
            ]
        CEUnwrapMaybe v_6_0 v_6_1 v_6_2 -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "CEUnwrapMaybe"
            , Tuple.pair "0"
                <| encodeValueInfo
                    v_6_0
            , Tuple.pair "1"
                <| encodeCodeBlock
                    v_6_1
            , Tuple.pair "2"
                <| encodeCodeBlock
                    v_6_2
            ]
        CEIf v_6_0 v_6_1 v_6_2 -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "CEIf"
            , Tuple.pair "0"
                <| encodeValueInfo
                    v_6_0
            , Tuple.pair "1"
                <| encodeCodeBlock
                    v_6_1
            , Tuple.pair "2"
                <| encodeCodeBlock
                    v_6_2
            ]
        CEFor v_6_0 v_6_1 v_6_2 v_6_3 -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "CEFor"
            , Tuple.pair "0"
                <| encodeValueInfo
                    v_6_0
            , Tuple.pair "1"
                <| encodeValueInfo
                    v_6_1
            , Tuple.pair "2"
                <| encodeValueInfo
                    v_6_2
            , Tuple.pair "3"
                <| encodeCodeBlock
                    v_6_3
            ]
        CEWhile v_6_0 v_6_1 -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "CEWhile"
            , Tuple.pair "0"
                <| encodeValueInfo
                    v_6_0
            , Tuple.pair "1"
                <| encodeCodeBlock
                    v_6_1
            ]
        CEBreak -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "CEBreak"
            ]
        CEForeachList v_6_0 v_6_1 -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "CEForeachList"
            , Tuple.pair "0"
                <| encodeValueInfo
                    v_6_0
            , Tuple.pair "1"
                <| encodeCodeBlock
                    v_6_1
            ]
        CEForeachDict v_6_0 v_6_1 -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "CEForeachDict"
            , Tuple.pair "0"
                <| encodeValueInfo
                    v_6_0
            , Tuple.pair "1"
                <| encodeCodeBlock
                    v_6_1
            ]
        CEEndGame -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "CEEndGame"
            ]
        CEJust v_6_0 -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "CEJust"
            , Tuple.pair "0"
                <| encodeValueInfo
                    v_6_0
            ]
        CENothing -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "CENothing"
            ]
        CEList v_6_0 -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "CEList"
            , Tuple.pair "0"
                <| ( Json.Encode.list
                        encodeValueInfo
                    )
                    v_6_0
            ]
        CEPut v_6_0 v_6_1 -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "CEPut"
            , Tuple.pair "0"
                <| Json.Encode.string
                    v_6_0
            , Tuple.pair "1"
                <| encodeValueInfo
                    v_6_1
            ]
        CEGetPlayer v_6_0 v_6_1 -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "CEGetPlayer"
            , Tuple.pair "0"
                <| encodeValueInfo
                    v_6_0
            , Tuple.pair "1"
                <| encodeValueInfo
                    v_6_1
            ]
        CESetRoomPermission v_6_0 v_6_1 v_6_2 v_6_3 -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "CESetRoomPermission"
            , Tuple.pair "0"
                <| encodeValueInfo
                    v_6_0
            , Tuple.pair "1"
                <| encodeValueInfo
                    v_6_1
            , Tuple.pair "2"
                <| encodeValueInfo
                    v_6_2
            , Tuple.pair "3"
                <| encodeValueInfo
                    v_6_3
            ]
        CEInformVoting v_6_0 v_6_1 v_6_2 -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "CEInformVoting"
            , Tuple.pair "0"
                <| encodeValueInfo
                    v_6_0
            , Tuple.pair "1"
                <| encodeValueInfo
                    v_6_1
            , Tuple.pair "2"
                <| encodeValueInfo
                    v_6_2
            ]
        CEAddRoleVisibility v_6_0 v_6_1 v_6_2 -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "CEAddRoleVisibility"
            , Tuple.pair "0"
                <| encodeValueInfo
                    v_6_0
            , Tuple.pair "1"
                <| encodeValueInfo
                    v_6_1
            , Tuple.pair "2"
                <| encodeValueInfo
                    v_6_2
            ]
        CEFilterTopScore v_6_0 -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "CEFilterTopScore"
            , Tuple.pair "0"
                <| encodeValueInfo
                    v_6_0
            ]
        CEFilterPlayer v_6_0 v_6_1 v_6_2 -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "CEFilterPlayer"
            , Tuple.pair "0"
                <| encodeValueInfo
                    v_6_0
            , Tuple.pair "1"
                <| encodeValueInfo
                    v_6_1
            , Tuple.pair "2"
                <| encodeValueInfo
                    v_6_2
            ]
        CEPlayerId v_6_0 -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "CEPlayerId"
            , Tuple.pair "0"
                <| encodeValueInfo
                    v_6_0
            ]
        CEPlayerAlive v_6_0 -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "CEPlayerAlive"
            , Tuple.pair "0"
                <| encodeValueInfo
                    v_6_0
            ]
        CEPlayerExtraWolfLive v_6_0 -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "CEPlayerExtraWolfLive"
            , Tuple.pair "0"
                <| encodeValueInfo
                    v_6_0
            ]
        CEPlayerHasRole v_6_0 v_6_1 -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "CEPlayerHasRole"
            , Tuple.pair "0"
                <| encodeValueInfo
                    v_6_0
            , Tuple.pair "1"
                <| encodeValueInfo
                    v_6_1
            ]
        CEPlayerAddRole v_6_0 v_6_1 -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "CEPlayerAddRole"
            , Tuple.pair "0"
                <| encodeValueInfo
                    v_6_0
            , Tuple.pair "1"
                <| encodeValueInfo
                    v_6_1
            ]
        CEPlayerRemoveRole v_6_0 v_6_1 -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "CEPlayerRemoveRole"
            , Tuple.pair "0"
                <| encodeValueInfo
                    v_6_0
            , Tuple.pair "1"
                <| encodeValueInfo
                    v_6_1
            ]
    )

decodeCodeElement : Json.Decode.Decoder CodeElement
decodeCodeElement =
    Json.Decode.field "type" Json.Decode.string
        |> Json.Decode.andThen
        (\v_6 -> case v_6 of
            "CESetTo" -> Json.Decode.succeed CESetTo
                |> Json.Decode.Pipeline.required "0"
                    ( decodeValueInfo
                    )
                |> Json.Decode.Pipeline.required "1"
                    ( Json.Decode.string
                    )
            "CEMath" -> Json.Decode.succeed CEMath
                |> Json.Decode.Pipeline.required "0"
                    ( decodeValueInfo
                    )
                |> Json.Decode.Pipeline.required "1"
                    ( decodeMathOperator
                    )
                |> Json.Decode.Pipeline.required "2"
                    ( decodeValueInfo
                    )
            "CECompare" -> Json.Decode.succeed CECompare
                |> Json.Decode.Pipeline.required "0"
                    ( decodeValueInfo
                    )
                |> Json.Decode.Pipeline.required "1"
                    ( decodeCompareOperator
                    )
                |> Json.Decode.Pipeline.required "2"
                    ( decodeValueInfo
                    )
            "CEBoolOp" -> Json.Decode.succeed CEBoolOp
                |> Json.Decode.Pipeline.required "0"
                    ( decodeValueInfo
                    )
                |> Json.Decode.Pipeline.required "1"
                    ( decodeBoolOperator
                    )
                |> Json.Decode.Pipeline.required "2"
                    ( decodeValueInfo
                    )
            "CEConcat" -> Json.Decode.succeed CEConcat
                |> Json.Decode.Pipeline.required "0"
                    ( decodeValueInfo
                    )
                |> Json.Decode.Pipeline.required "1"
                    ( decodeValueInfo
                    )
            "CEListGet" -> Json.Decode.succeed CEListGet
                |> Json.Decode.Pipeline.required "0"
                    ( decodeValueInfo
                    )
                |> Json.Decode.Pipeline.required "1"
                    ( decodeValueInfo
                    )
            "CEDictGet" -> Json.Decode.succeed CEDictGet
                |> Json.Decode.Pipeline.required "0"
                    ( decodeValueInfo
                    )
                |> Json.Decode.Pipeline.required "1"
                    ( decodeValueInfo
                    )
            "CETupleFirst" -> Json.Decode.succeed CETupleFirst
                |> Json.Decode.Pipeline.required "0"
                    ( decodeValueInfo
                    )
            "CETupleSecond" -> Json.Decode.succeed CETupleSecond
                |> Json.Decode.Pipeline.required "0"
                    ( decodeValueInfo
                    )
            "CEUnwrapMaybe" -> Json.Decode.succeed CEUnwrapMaybe
                |> Json.Decode.Pipeline.required "0"
                    ( decodeValueInfo
                    )
                |> Json.Decode.Pipeline.required "1"
                    ( decodeCodeBlock
                    )
                |> Json.Decode.Pipeline.required "2"
                    ( decodeCodeBlock
                    )
            "CEIf" -> Json.Decode.succeed CEIf
                |> Json.Decode.Pipeline.required "0"
                    ( decodeValueInfo
                    )
                |> Json.Decode.Pipeline.required "1"
                    ( decodeCodeBlock
                    )
                |> Json.Decode.Pipeline.required "2"
                    ( decodeCodeBlock
                    )
            "CEFor" -> Json.Decode.succeed CEFor
                |> Json.Decode.Pipeline.required "0"
                    ( decodeValueInfo
                    )
                |> Json.Decode.Pipeline.required "1"
                    ( decodeValueInfo
                    )
                |> Json.Decode.Pipeline.required "2"
                    ( decodeValueInfo
                    )
                |> Json.Decode.Pipeline.required "3"
                    ( decodeCodeBlock
                    )
            "CEWhile" -> Json.Decode.succeed CEWhile
                |> Json.Decode.Pipeline.required "0"
                    ( decodeValueInfo
                    )
                |> Json.Decode.Pipeline.required "1"
                    ( decodeCodeBlock
                    )
            "CEBreak" -> Json.Decode.succeed CEBreak
            "CEForeachList" -> Json.Decode.succeed CEForeachList
                |> Json.Decode.Pipeline.required "0"
                    ( decodeValueInfo
                    )
                |> Json.Decode.Pipeline.required "1"
                    ( decodeCodeBlock
                    )
            "CEForeachDict" -> Json.Decode.succeed CEForeachDict
                |> Json.Decode.Pipeline.required "0"
                    ( decodeValueInfo
                    )
                |> Json.Decode.Pipeline.required "1"
                    ( decodeCodeBlock
                    )
            "CEEndGame" -> Json.Decode.succeed CEEndGame
            "CEJust" -> Json.Decode.succeed CEJust
                |> Json.Decode.Pipeline.required "0"
                    ( decodeValueInfo
                    )
            "CENothing" -> Json.Decode.succeed CENothing
            "CEList" -> Json.Decode.succeed CEList
                |> Json.Decode.Pipeline.required "0"
                    ( Json.Decode.list
                        ( decodeValueInfo
                        )
                    )
            "CEPut" -> Json.Decode.succeed CEPut
                |> Json.Decode.Pipeline.required "0"
                    ( Json.Decode.string
                    )
                |> Json.Decode.Pipeline.required "1"
                    ( decodeValueInfo
                    )
            "CEGetPlayer" -> Json.Decode.succeed CEGetPlayer
                |> Json.Decode.Pipeline.required "0"
                    ( decodeValueInfo
                    )
                |> Json.Decode.Pipeline.required "1"
                    ( decodeValueInfo
                    )
            "CESetRoomPermission" -> Json.Decode.succeed CESetRoomPermission
                |> Json.Decode.Pipeline.required "0"
                    ( decodeValueInfo
                    )
                |> Json.Decode.Pipeline.required "1"
                    ( decodeValueInfo
                    )
                |> Json.Decode.Pipeline.required "2"
                    ( decodeValueInfo
                    )
                |> Json.Decode.Pipeline.required "3"
                    ( decodeValueInfo
                    )
            "CEInformVoting" -> Json.Decode.succeed CEInformVoting
                |> Json.Decode.Pipeline.required "0"
                    ( decodeValueInfo
                    )
                |> Json.Decode.Pipeline.required "1"
                    ( decodeValueInfo
                    )
                |> Json.Decode.Pipeline.required "2"
                    ( decodeValueInfo
                    )
            "CEAddRoleVisibility" -> Json.Decode.succeed CEAddRoleVisibility
                |> Json.Decode.Pipeline.required "0"
                    ( decodeValueInfo
                    )
                |> Json.Decode.Pipeline.required "1"
                    ( decodeValueInfo
                    )
                |> Json.Decode.Pipeline.required "2"
                    ( decodeValueInfo
                    )
            "CEFilterTopScore" -> Json.Decode.succeed CEFilterTopScore
                |> Json.Decode.Pipeline.required "0"
                    ( decodeValueInfo
                    )
            "CEFilterPlayer" -> Json.Decode.succeed CEFilterPlayer
                |> Json.Decode.Pipeline.required "0"
                    ( decodeValueInfo
                    )
                |> Json.Decode.Pipeline.required "1"
                    ( decodeValueInfo
                    )
                |> Json.Decode.Pipeline.required "2"
                    ( decodeValueInfo
                    )
            "CEPlayerId" -> Json.Decode.succeed CEPlayerId
                |> Json.Decode.Pipeline.required "0"
                    ( decodeValueInfo
                    )
            "CEPlayerAlive" -> Json.Decode.succeed CEPlayerAlive
                |> Json.Decode.Pipeline.required "0"
                    ( decodeValueInfo
                    )
            "CEPlayerExtraWolfLive" -> Json.Decode.succeed CEPlayerExtraWolfLive
                |> Json.Decode.Pipeline.required "0"
                    ( decodeValueInfo
                    )
            "CEPlayerHasRole" -> Json.Decode.succeed CEPlayerHasRole
                |> Json.Decode.Pipeline.required "0"
                    ( decodeValueInfo
                    )
                |> Json.Decode.Pipeline.required "1"
                    ( decodeValueInfo
                    )
            "CEPlayerAddRole" -> Json.Decode.succeed CEPlayerAddRole
                |> Json.Decode.Pipeline.required "0"
                    ( decodeValueInfo
                    )
                |> Json.Decode.Pipeline.required "1"
                    ( decodeValueInfo
                    )
            "CEPlayerRemoveRole" -> Json.Decode.succeed CEPlayerRemoveRole
                |> Json.Decode.Pipeline.required "0"
                    ( decodeValueInfo
                    )
                |> Json.Decode.Pipeline.required "1"
                    ( decodeValueInfo
                    )
            _ -> Json.Decode.fail <| "no representation of variant " ++ v_6 ++ " found"
        )

encodeCodeElementInfo : CodeElementInfo -> Json.Encode.Value
encodeCodeElementInfo =
    (\g_3 -> Json.Encode.object
        [ Tuple.pair "key"
            <| Json.Encode.string
                g_3.key
        , Tuple.pair "name"
            <| Json.Encode.string
                g_3.name
        , Tuple.pair "desc"
            <| Json.Encode.string
                g_3.desc
        , Tuple.pair "type_"
            <| encodeTypeInfo
                g_3.type_
        , Tuple.pair "init"
            <| encodeCodeElement
                g_3.init
        ]
    )

decodeCodeElementInfo : Json.Decode.Decoder CodeElementInfo
decodeCodeElementInfo =
    Json.Decode.succeed
        (\g_3_key g_3_name g_3_desc g_3_type_ g_3_init ->
            { key = g_3_key
            , name = g_3_name
            , desc = g_3_desc
            , type_ = g_3_type_
            , init = g_3_init
            }
        )
        |> Json.Decode.Pipeline.required "key"
            ( Json.Decode.string
            )
        |> Json.Decode.Pipeline.required "name"
            ( Json.Decode.string
            )
        |> Json.Decode.Pipeline.required "desc"
            ( Json.Decode.string
            )
        |> Json.Decode.Pipeline.required "type_"
            ( decodeTypeInfo
            )
        |> Json.Decode.Pipeline.required "init"
            ( decodeCodeElement
            )

encodeVarDefinition : VarDefinition -> Json.Encode.Value
encodeVarDefinition =
    (\g_4 -> Json.Encode.object
        [ Tuple.pair "redefinition"
            <| Json.Encode.int
                g_4.redefinition
        , Tuple.pair "type_"
            <| encodeTypeInfo
                g_4.type_
        , Tuple.pair "readonly"
            <| Json.Encode.bool
                g_4.readonly
        ]
    )

decodeVarDefinition : Json.Decode.Decoder VarDefinition
decodeVarDefinition =
    Json.Decode.succeed
        (\g_4_redefinition g_4_type_ g_4_readonly ->
            { redefinition = g_4_redefinition
            , type_ = g_4_type_
            , readonly = g_4_readonly
            }
        )
        |> Json.Decode.Pipeline.required "redefinition"
            ( Json.Decode.int
            )
        |> Json.Decode.Pipeline.required "type_"
            ( decodeTypeInfo
            )
        |> Json.Decode.Pipeline.required "readonly"
            ( Json.Decode.bool
            )

encodeErrorNode : ErrorNode -> Json.Encode.Value
encodeErrorNode =
    (\v_7 -> case v_7 of
        ErrorNode v_7_0 -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "ErrorNode"
            , Tuple.pair "0"
                <| (\g_5 -> Json.Encode.object
                        [ Tuple.pair "errors"
                            <| ( Json.Encode.list
                                    Json.Encode.string
                                )
                                g_5.errors
                        , Tuple.pair "nodes"
                            <| ( Json.Encode.dict
                                    ( Json.Encode.encode 0
                                        <<Json.Encode.int
                                    )
                                    <| encodeErrorNode
                            )g_5.nodes
                        ]
                    )
                    v_7_0
            ]
    )

decodeErrorNode : Json.Decode.Decoder ErrorNode
decodeErrorNode =
    Json.Decode.field "type" Json.Decode.string
        |> Json.Decode.andThen
        (\v_7 -> case v_7 of
            "ErrorNode" -> Json.Decode.succeed ErrorNode
                |> Json.Decode.Pipeline.required "0"
                    ( Json.Decode.succeed
                        (\g_5_errors g_5_nodes ->
                            { errors = g_5_errors
                            , nodes = g_5_nodes
                            }
                        )
                        |> Json.Decode.Pipeline.required "errors"
                            ( Json.Decode.list
                                ( Json.Decode.string
                                )
                            )
                        |> Json.Decode.Pipeline.required "nodes"
                            ( Json.Decode.andThen
                                (\dd_0_d -> Dict.toList dd_0_d
                                    |> List.map
                                        (\(dd_0_k, dd_0_v) ->
                                            ( Json.Decode.decodeString
                                                (Json.Decode.int
                                                )
                                                dd_0_k
                                            , dd_0_v
                                            )
                                        )
                                    |> \d_0_l ->
                                        if List.any
                                            (\(dd_0_k, dd_0_v) -> case dd_0_k of
                                                Ok _ -> False
                                                Err _ -> True
                                            )
                                            d_0_l
                                        then Json.Decode.fail "cannot convert some keys"
                                        else Json.Decode.succeed
                                            <| Dict.fromList
                                            <| List.filterMap
                                                (\(dd_0_k, dd_0_v) -> case dd_0_k of
                                                    Ok dd_0_rk -> Just (dd_0_rk, dd_0_v)
                                                    Err _ -> Nothing
                                                )
                                            <| d_0_l
                                )
                                <| Json.Decode.dict
                                <| decodeErrorNode
                            )
                    )
            _ -> Json.Decode.fail <| "no representation of variant " ++ v_7 ++ " found"
        )

encodeVarEnvironment : VarEnvironment -> Json.Encode.Value
encodeVarEnvironment =
    (\g_6 -> Json.Encode.object
        [ Tuple.pair "vars"
            <| ( Json.Encode.dict identity
                    <| encodeVarDefinition
                )
                g_6.vars
        , Tuple.pair "chatKey"
            <| ( Json.Encode.set
                    Json.Encode.string
                )
                g_6.chatKey
        , Tuple.pair "phaseKey"
            <| ( Json.Encode.set
                    Json.Encode.string
                )
                g_6.phaseKey
        , Tuple.pair "roleKey"
            <| ( Json.Encode.set
                    Json.Encode.string
                )
                g_6.roleKey
        , Tuple.pair "votingKey"
            <| ( Json.Encode.set
                    Json.Encode.string
                )
                g_6.votingKey
        ]
    )

decodeVarEnvironment : Json.Decode.Decoder VarEnvironment
decodeVarEnvironment =
    Json.Decode.succeed
        (\g_6_vars g_6_chatKey g_6_phaseKey g_6_roleKey g_6_votingKey ->
            { vars = g_6_vars
            , chatKey = g_6_chatKey
            , phaseKey = g_6_phaseKey
            , roleKey = g_6_roleKey
            , votingKey = g_6_votingKey
            }
        )
        |> Json.Decode.Pipeline.required "vars"
            ( Json.Decode.dict
                <| decodeVarDefinition
            )
        |> Json.Decode.Pipeline.required "chatKey"
            ( Json.Decode.map Set.fromList
                <| Json.Decode.list
                <| Json.Decode.string
            )
        |> Json.Decode.Pipeline.required "phaseKey"
            ( Json.Decode.map Set.fromList
                <| Json.Decode.list
                <| Json.Decode.string
            )
        |> Json.Decode.Pipeline.required "roleKey"
            ( Json.Decode.map Set.fromList
                <| Json.Decode.list
                <| Json.Decode.string
            )
        |> Json.Decode.Pipeline.required "votingKey"
            ( Json.Decode.map Set.fromList
                <| Json.Decode.list
                <| Json.Decode.string
            )

encodeCodeEditEntry : CodeEditEntry -> Json.Encode.Value
encodeCodeEditEntry =
    (\v_8 -> case v_8 of
        CEEValue v_8_0 v_8_1 -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "CEEValue"
            , Tuple.pair "0"
                <| Json.Encode.string
                    v_8_0
            , Tuple.pair "1"
                <| encodeValueInfo
                    v_8_1
            ]
        CEEParameter v_8_0 v_8_1 -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "CEEParameter"
            , Tuple.pair "0"
                <| Json.Encode.string
                    v_8_0
            , Tuple.pair "1"
                <| encodeTypeInfo
                    v_8_1
            ]
        CEEBlock v_8_0 v_8_1 -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "CEEBlock"
            , Tuple.pair "0"
                <| Json.Encode.string
                    v_8_0
            , Tuple.pair "1"
                <| encodeCodeBlock
                    v_8_1
            ]
        CEEMath v_8_0 -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "CEEMath"
            , Tuple.pair "0"
                <| encodeMathOperator
                    v_8_0
            ]
        CEECompare v_8_0 -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "CEECompare"
            , Tuple.pair "0"
                <| encodeCompareOperator
                    v_8_0
            ]
        CEEBool v_8_0 -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "CEEBool"
            , Tuple.pair "0"
                <| encodeBoolOperator
                    v_8_0
            ]
        CEEList v_8_0 v_8_1 -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "CEEList"
            , Tuple.pair "0"
                <| encodeCodeEditEntry
                    v_8_0
            , Tuple.pair "1"
                <| ( Json.Encode.list
                        encodeCodeEditEntry
                    )
                    v_8_1
            ]
    )

decodeCodeEditEntry : Json.Decode.Decoder CodeEditEntry
decodeCodeEditEntry =
    Json.Decode.field "type" Json.Decode.string
        |> Json.Decode.andThen
        (\v_8 -> case v_8 of
            "CEEValue" -> Json.Decode.succeed CEEValue
                |> Json.Decode.Pipeline.required "0"
                    ( Json.Decode.string
                    )
                |> Json.Decode.Pipeline.required "1"
                    ( decodeValueInfo
                    )
            "CEEParameter" -> Json.Decode.succeed CEEParameter
                |> Json.Decode.Pipeline.required "0"
                    ( Json.Decode.string
                    )
                |> Json.Decode.Pipeline.required "1"
                    ( decodeTypeInfo
                    )
            "CEEBlock" -> Json.Decode.succeed CEEBlock
                |> Json.Decode.Pipeline.required "0"
                    ( Json.Decode.string
                    )
                |> Json.Decode.Pipeline.required "1"
                    ( decodeCodeBlock
                    )
            "CEEMath" -> Json.Decode.succeed CEEMath
                |> Json.Decode.Pipeline.required "0"
                    ( decodeMathOperator
                    )
            "CEECompare" -> Json.Decode.succeed CEECompare
                |> Json.Decode.Pipeline.required "0"
                    ( decodeCompareOperator
                    )
            "CEEBool" -> Json.Decode.succeed CEEBool
                |> Json.Decode.Pipeline.required "0"
                    ( decodeBoolOperator
                    )
            "CEEList" -> Json.Decode.succeed CEEList
                |> Json.Decode.Pipeline.required "0"
                    ( decodeCodeEditEntry
                    )
                |> Json.Decode.Pipeline.required "1"
                    ( Json.Decode.list
                        ( decodeCodeEditEntry
                        )
                    )
            _ -> Json.Decode.fail <| "no representation of variant " ++ v_8 ++ " found"
        )

encodeCodeCategory : CodeCategory -> Json.Encode.Value
encodeCodeCategory =
    (\v_9 -> case v_9 of
        CCCalculation -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "CCCalculation"
            ]
        CCVariables -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "CCVariables"
            ]
        CCBranches -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "CCBranches"
            ]
        CCUtility -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "CCUtility"
            ]
    )

decodeCodeCategory : Json.Decode.Decoder CodeCategory
decodeCodeCategory =
    Json.Decode.field "type" Json.Decode.string
        |> Json.Decode.andThen
        (\v_9 -> case v_9 of
            "CCCalculation" -> Json.Decode.succeed CCCalculation
            "CCVariables" -> Json.Decode.succeed CCVariables
            "CCBranches" -> Json.Decode.succeed CCBranches
            "CCUtility" -> Json.Decode.succeed CCUtility
            _ -> Json.Decode.fail <| "no representation of variant " ++ v_9 ++ " found"
        )

encodeCodeElementEditInfo : CodeElementEditInfo -> Json.Encode.Value
encodeCodeElementEditInfo =
    (\g_7 -> Json.Encode.object
        [ Tuple.pair "key"
            <| Json.Encode.string
                g_7.key
        , Tuple.pair "category"
            <| encodeCodeCategory
                g_7.category
        , Tuple.pair "entrys"
            <| ( Json.Encode.list
                    encodeCodeEditEntry
                )
                g_7.entrys
        ]
    )

decodeCodeElementEditInfo : Json.Decode.Decoder CodeElementEditInfo
decodeCodeElementEditInfo =
    Json.Decode.succeed
        (\g_7_key g_7_category g_7_entrys ->
            { key = g_7_key
            , category = g_7_category
            , entrys = g_7_entrys
            }
        )
        |> Json.Decode.Pipeline.required "key"
            ( Json.Decode.string
            )
        |> Json.Decode.Pipeline.required "category"
            ( decodeCodeCategory
            )
        |> Json.Decode.Pipeline.required "entrys"
            ( Json.Decode.list
                ( decodeCodeEditEntry
                )
            )

encodeCodeEnvironment : CodeEnvironment -> Json.Encode.Value
encodeCodeEnvironment =
    (\g_8 -> Json.Encode.object
        [ Tuple.pair "blocks"
            <| ( Json.Encode.dict identity
                    <| encodeCodeEnvironmentBlockType
                )
                g_8.blocks
        , Tuple.pair "clipboard"
            <| ( Json.Encode.list
                    encodeCodeBlock
                )
                g_8.clipboard
        ]
    )

decodeCodeEnvironment : Json.Decode.Decoder CodeEnvironment
decodeCodeEnvironment =
    Json.Decode.succeed
        (\g_8_blocks g_8_clipboard ->
            { blocks = g_8_blocks
            , clipboard = g_8_clipboard
            }
        )
        |> Json.Decode.Pipeline.required "blocks"
            ( Json.Decode.dict
                <| decodeCodeEnvironmentBlockType
            )
        |> Json.Decode.Pipeline.required "clipboard"
            ( Json.Decode.list
                ( decodeCodeBlock
                )
            )

encodeCodeEnvironmentBlockType : CodeEnvironmentBlockType -> Json.Encode.Value
encodeCodeEnvironmentBlockType =
    (\v_10 -> case v_10 of
        CEBTDirect v_10_0 -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "CEBTDirect"
            , Tuple.pair "0"
                <| encodeCodeBlock
                    v_10_0
            ]
        CEBTPhased v_10_0 v_10_1 -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "CEBTPhased"
            , Tuple.pair "0"
                <| encodeCodeBlock
                    v_10_0
            , Tuple.pair "1"
                <| ( Json.Encode.dict identity
                        <| encodeCodeBlock
                    )
                    v_10_1
            ]
        CEBTRoled v_10_0 v_10_1 -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "CEBTRoled"
            , Tuple.pair "0"
                <| encodeCodeBlock
                    v_10_0
            , Tuple.pair "1"
                <| ( Json.Encode.dict identity
                        <| encodeCodeBlock
                    )
                    v_10_1
            ]
        CEBTRoomName v_10_0 v_10_1 -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "CEBTRoomName"
            , Tuple.pair "0"
                <| encodeCodeBlock
                    v_10_0
            , Tuple.pair "1"
                <| ( Json.Encode.dict
                        ( Json.Encode.encode 0
                            <<(\(t_0_0, t_0_1) -> Json.Encode.list identity
                                [ Json.Encode.string
                                    t_0_0
                                , Json.Encode.string
                                    t_0_1
                                ]
                            )
                        )
                        <| encodeCodeBlock
                )v_10_1
            ]
    )

decodeCodeEnvironmentBlockType : Json.Decode.Decoder CodeEnvironmentBlockType
decodeCodeEnvironmentBlockType =
    Json.Decode.field "type" Json.Decode.string
        |> Json.Decode.andThen
        (\v_10 -> case v_10 of
            "CEBTDirect" -> Json.Decode.succeed CEBTDirect
                |> Json.Decode.Pipeline.required "0"
                    ( decodeCodeBlock
                    )
            "CEBTPhased" -> Json.Decode.succeed CEBTPhased
                |> Json.Decode.Pipeline.required "0"
                    ( decodeCodeBlock
                    )
                |> Json.Decode.Pipeline.required "1"
                    ( Json.Decode.dict
                        <| decodeCodeBlock
                    )
            "CEBTRoled" -> Json.Decode.succeed CEBTRoled
                |> Json.Decode.Pipeline.required "0"
                    ( decodeCodeBlock
                    )
                |> Json.Decode.Pipeline.required "1"
                    ( Json.Decode.dict
                        <| decodeCodeBlock
                    )
            "CEBTRoomName" -> Json.Decode.succeed CEBTRoomName
                |> Json.Decode.Pipeline.required "0"
                    ( decodeCodeBlock
                    )
                |> Json.Decode.Pipeline.required "1"
                    ( Json.Decode.andThen
                        (\dd_1_d -> Dict.toList dd_1_d
                            |> List.map
                                (\(dd_1_k, dd_1_v) ->
                                    ( Json.Decode.decodeString
                                        (Json.Decode.succeed
                                                (\t_0_0 t_0_1 -> (t_0_0, t_0_1))
                                            |> Json.Decode.Pipeline.custom
                                                ( Json.Decode.index 0
                                                    ( Json.Decode.string
                                                    )
                                                )
                                            |> Json.Decode.Pipeline.custom
                                                ( Json.Decode.index 1
                                                    ( Json.Decode.string
                                                    )
                                                )
                                        )
                                        dd_1_k
                                    , dd_1_v
                                    )
                                )
                            |> \d_1_l ->
                                if List.any
                                    (\(dd_1_k, dd_1_v) -> case dd_1_k of
                                        Ok _ -> False
                                        Err _ -> True
                                    )
                                    d_1_l
                                then Json.Decode.fail "cannot convert some keys"
                                else Json.Decode.succeed
                                    <| Dict.fromList
                                    <| List.filterMap
                                        (\(dd_1_k, dd_1_v) -> case dd_1_k of
                                            Ok dd_1_rk -> Just (dd_1_rk, dd_1_v)
                                            Err _ -> Nothing
                                        )
                                    <| d_1_l
                        )
                        <| Json.Decode.dict
                        <| decodeCodeBlock
                    )
            _ -> Json.Decode.fail <| "no representation of variant " ++ v_10 ++ " found"
        )

encodeCodeEnvironmentPath : (path -> Json.Encode.Value) -> (CodeEnvironmentPath path) -> Json.Encode.Value
encodeCodeEnvironmentPath conv_path =
    (\v_11 -> case v_11 of
        CEPBlocks v_11_0 v_11_1 -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "CEPBlocks"
            , Tuple.pair "0"
                <| ( Json.Encode.list
                        Json.Encode.string
                    )
                    v_11_0
            , Tuple.pair "1"
                <| conv_path
                    v_11_1
            ]
        CEPClipboard v_11_0 v_11_1 -> Json.Encode.object
            [ Tuple.pair "type"
                <| Json.Encode.string "CEPClipboard"
            , Tuple.pair "0"
                <| Json.Encode.int
                    v_11_0
            , Tuple.pair "1"
                <| conv_path
                    v_11_1
            ]
    )

decodeCodeEnvironmentPath : Json.Decode.Decoder path -> Json.Decode.Decoder (CodeEnvironmentPath path)
decodeCodeEnvironmentPath conv_path =
    Json.Decode.field "type" Json.Decode.string
        |> Json.Decode.andThen
        (\v_11 -> case v_11 of
            "CEPBlocks" -> Json.Decode.succeed CEPBlocks
                |> Json.Decode.Pipeline.required "0"
                    ( Json.Decode.list
                        ( Json.Decode.string
                        )
                    )
                |> Json.Decode.Pipeline.required "1"
                    ( conv_path
                    )
            "CEPClipboard" -> Json.Decode.succeed CEPClipboard
                |> Json.Decode.Pipeline.required "0"
                    ( Json.Decode.int
                    )
                |> Json.Decode.Pipeline.required "1"
                    ( conv_path
                    )
            _ -> Json.Decode.fail <| "no representation of variant " ++ v_11 ++ " found"
        )


