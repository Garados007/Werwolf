module Dashboard.Editor.Token exposing (..)

import Dashboard.Editor.Logic exposing (..)
import Dashboard.Source as Source exposing (Source (..), textnl)
import Dashboard.Environment exposing (Environment, RoleSetup)
import Regex
import Dict exposing (Dict)
import Set
import List.Extra as LE
import Json.Encode as JE

type alias ParseEnvironment =
    { global : Environment
    , code : CodeEnvironment
    , role : RoleSetup
    , level : Int
    }

nl : Source
nl = SNewLine

text : String -> Source 
text = SText

bool : Bool -> Source 
bool v = SText <|
    if v then "true" else "false"

moduleName : Environment -> String 
moduleName env = env.moduleName
    |> String.toLower
    |> Regex.replace
        (Regex.fromString "[^a-z0-9_]" |> Maybe.withDefault Regex.never)
        (always "_")

codeEnvironment : ParseEnvironment -> Source 
codeEnvironment env = SMulti
    [ textnl "<?php"
    , nl
    , textnl "include_once __DIR__ . '/../RoleBase.php';"
    , nl
    , text "class "
    , text <| moduleName env.global
    , text "_"
    , text env.role.key
    , textnl " extends RoleBase {"
    , SIndent 1
    , constructor env
    , SMulti
        <| List.intersperse SNewLine
        <| List.map (\(k,b) -> rootFunc env k b)
        <| Dict.toList env.code.blocks
    , SIndent -1
    , textnl "}"
    ]

constructor : ParseEnvironment -> Source 
constructor env = SMulti 
    [ textnl "public function __construct() {"
    , SIndent 1
    , text "$this->roleName = '"
    , text env.role.key
    , textnl "';"
    , text "$this->canStartNewRound = ", bool env.role.canStartNewRound, textnl ";"
    , text "$this->canStartVotings = ", bool env.role.canStartVotings, textnl ";"
    , text "$this->canStopVotings = ", bool env.role.canStopVotings, textnl ";"
    , text "$this->isFractionRole = "
    , bool 
        <| List.member env.role.key
        <| Dict.keys
        <| env.global.game.fractions
    , textnl ";"
    , SIndent -1
    , textnl "}"
    , SNewLine
    ]

getMethodArg : CodeBlock -> Int -> String -> String 
getMethodArg block index default = block.vars 
    |> LE.getAt index
    |> Maybe.map .key
    |> Maybe.withDefault default

rootFunc : ParseEnvironment -> String -> CodeEnvironmentBlockType -> Source
rootFunc env key block = case key of 
    "onStartRound" -> codeEnvironmentBlock env key block 
        [ "round" ]
        [ text "$round->phase" ]
        SNone 
        (\b -> outCodeBlock env b
            <| SMulti
                [ text "$u_"
                , text <| getMethodArg b 0 "round"
                , textnl " = $round->round;"
                ]
        )
        (SMulti
            [ textnl "switch ($round->round) {"
            , SIndent 1
            , SMulti
                <| List.map 
                    (\(k, d) -> SMulti
                        [ text "case '"
                        , text k
                        , textnl "': "
                        , SIndent 1
                        , SMulti
                            <| List.map 
                                (\(c,p) -> SMulti
                                    [ text "$this->setRoomPermission('"
                                    , text c
                                    , text "', "
                                    , bool p.read
                                    , text ", "
                                    , bool p.write
                                    , text ", "
                                    , bool p.visible
                                    , textnl ");"
                                    ]
                                )
                            <| Dict.toList d
                        , textnl "break;"
                        , SIndent -1
                        ]
                    )
                <| Dict.toList env.role.permissions
            , SIndent -1
            , textnl "}"
            ]
        )
    "onLeaveRound" -> codeEnvironmentBlock env key block 
        [ "round" ]
        [ text "$round->phase" ]
        SNone
        (\b -> outCodeBlock env b
            <| SMulti
                [ text "$u_"
                , text <| getMethodArg b 0 "round"
                , textnl " = $round->round;"
                ]
        )
        SNone
    "needToExecuteRound" -> codeEnvironmentBlock env key block 
        [ "round" ]
        [ text "$round->phase" ]
        SNone
        (\b -> outCodeBlock env b
            <| SMulti
                [ text "$u_"
                , text <| getMethodArg b 0 "round"
                , textnl " = $round->round;"
                ]
        )
        (SMulti 
            [ textnl "return in_array($round->phase, array("
            , SIndent 1
            , SMulti
                <| List.intersperse (textnl ",")
                <| List.map 
                    (\k -> SMulti
                        [ text "'"
                        , text k 
                        , text "'"
                        ]
                    )
                <| Set.toList env.role.reqPhases
            , if Set.isEmpty env.role.reqPhases
                then SNone else SNewLine
            , SIndent -1
            , textnl "));"
            ]
        )
    "isWinner" -> codeEnvironmentBlock env key block 
        [ "winnerRole", "player" ]
        [ text "$winnerRole" ]
        SNone
        (\b -> outCodeBlock env b 
            <| SMulti
                [ text "$u_"
                , text <| getMethodArg b 0 "caller"
                , textnl " = $player->player;"
                ]
        )
        (SMulti
            [ textnl "return in_array($winnerRole, array("
            , SIndent 1
            , SMulti
                <| List.intersperse (textnl ",")
                <| List.map 
                    (\s -> text <| "'" ++ s ++ "'")
                <| Set.toList env.role.winTogether
            , if Set.isEmpty env.role.winTogether
                then SNone else SNewLine
            , SIndent -1
            , textnl "));"
            ]
        )
    "canVote" -> codeEnvironmentBlock env key block 
        [ "room", "name" ]
        [ text "$room", text "$name" ]
        SNone
        (\b -> outCodeBlock env b SNone)
        ( SMulti
            [ textnl "switch ($room) {"
            , SIndent 1
            , SMulti
                <| List.map 
                    (\(k, s) -> SMulti
                        [ text "case '"
                        , text k
                        , textnl "':"
                        , SIndent 1
                        , textnl "return in_array($name, array("
                        , SIndent 1
                        , SMulti
                            <| List.intersperse (textnl ",")
                            <| List.map (\v -> text <| "'" ++ v ++ "'")
                            <| Set.toList s
                        , if Set.isEmpty s then SNone else SNewLine
                        , SIndent -1
                        , textnl "));"
                        , textnl "break;"
                        , SIndent -1
                        ]
                    )
                <| Dict.toList env.role.canVote
            , SIndent -1
            , textnl "}"
            ]
        )
    "onVotingCreated" -> codeEnvironmentBlock env key block 
        [ "room", "name" ]
        [ text "$room", text "$name" ]
        SNone
        (\b -> outCodeBlock env b SNone)
        SNone
    "onVotingStarts" -> codeEnvironmentBlock env key block 
        [ "room", "name" ]
        [ text "$room", text "$name" ]
        SNone
        (\b -> outCodeBlock env b SNone)
        SNone
    "onVotingStops" -> codeEnvironmentBlock env "onVotingStops2" block 
        [ "room", "name", "result", "voter" ]
        [ text "$room", text "$name" ]
        (textnl "self::onVotingStops($room, $name, $result);")
        (\b -> outCodeBlock env b
            <| SMulti
                [ text "$u_"
                , text <| getMethodArg b 0 "result"
                , textnl " = $result;"
                , text "$u_"
                , text <| getMethodArg b 1 "voter"
                , textnl " = $voter;"
                ]
        )
        SNone
    "onGameStarts" -> codeEnvironmentBlock env key block 
        [ "round" ]
        []
        (   -- no call of parent onGameStarts for fractions roles.
            -- if someone could see this role, so someone can dertermine
            -- itself which fractions the player belongs to or not.
            if List.member env.role.key
                <| Dict.keys
                <| env.global.game.fractions
            then SNone
            else textnl "parent::onGameStarts($round);"
        )
        (\b -> outCodeBlock env b 
            <| SMulti 
                [ text "$u_" 
                , text <| getMethodArg b 0 "round"
                , textnl " = $round->round;"
                , text "$u_"
                , text <| getMethodArg b 1 "phase"
                , textnl " = $round->phase;"
                ]
        )
        ( SMulti
            <| List.map 
                (\r -> SMulti
                    [ textnl "$this->addRoleVisibility("
                    , SIndent 1
                    , text "$this->getPlayer('"
                    , text env.role.key
                    , textnl "', true),"
                    , text "$this->getPlayer('"
                    , text r 
                    , textnl "', true),"
                    , textnl <| "'" ++ r ++ "'"
                    , SIndent -1
                    , textnl ");"
                    ]
                )
            <| List.filter ((/=) env.role.key)
            <| Set.toList env.role.initCanView
        )
    "onGameEnds" -> codeEnvironmentBlock env key block 
        [ "round", "teams" ]
        []
        SNone
        (\b -> outCodeBlock env b 
            <| SMulti 
                [ text "$u_" 
                , text <| getMethodArg b 0 "round"
                , textnl " = $round->round;"
                , text "$u_"
                , text <| getMethodArg b 1 "phase"
                , textnl " = $round->phase;"
                , text "$u_"
                , text <| getMethodArg b 2 "teams"
                , textnl " = $teams;"
                ]
        )
        SNone
    _ -> SNone

codeEnvironmentBlock : ParseEnvironment -> String -> CodeEnvironmentBlockType 
    -> List String -> List Source -> Source -> (CodeBlock -> Source) -> Source
    -> Source
codeEnvironmentBlock env key block funcVars intVars header content footer = 
    case block of 
        CEBTDirect b -> rootDirect env key funcVars
            <| SMulti
                [ header
                , content b
                , footer
                ]
        CEBTPhased _ d -> case intVars of 
            iv::_ -> rootPhased env key d funcVars iv header content footer
            _ -> SNone
        CEBTRoled _ d -> case intVars of 
            iv::_ -> rootRoled env key d funcVars iv header content footer
            _ -> SNone
        CEBTRoomName _ d -> case intVars of 
            iv1::iv2::_ -> rootRoomName env key d funcVars iv1 iv2 
                header content footer 
            _ -> SNone

rootDirect : ParseEnvironment -> String -> List String -> Source -> Source 
rootDirect env key vars content = SMulti 
    [ text "public function "
    , text key 
    , text "("
    , SMulti
        <| List.intersperse (text ", ")
        <| List.map 
            (\v -> SMulti
                [ text "$"
                , text v
                ]
            )
        <| vars
    , textnl ") {"
    , SIndent 1
    , content
    , SIndent -1
    , textnl "}"
    ]

rootPhased : ParseEnvironment -> String -> Dict String CodeBlock 
    -> List String -> Source -> Source -> (CodeBlock -> Source) 
    -> Source -> Source
rootPhased env key dict vars phaseVar header content footer = SMulti
    [ text "public function "
    , text key 
    , text "("
    , SMulti
        <| List.intersperse (text ", ")
        <| List.map 
            (\v -> SMulti
                [ text "$"
                , text v
                ]
            )
        <| vars
    , textnl ") {"
    , SIndent 1
    , header
    , if Dict.isEmpty dict 
        then SNone 
        else SMulti
            [ text "switch ("
            , phaseVar
            , textnl ") {"
            , SIndent 1
            , SMulti 
                <| List.map 
                    (\(k,block) -> SMulti
                        [ text "case '"
                        , text k
                        , textnl "': {"
                        , SIndent 1
                        , content block
                        , SIndent -1
                        , textnl "} break;"
                        ]
                    )
                <| Dict.toList dict
            , SIndent -1
            , textnl "}"
            ]
    , footer
    , SIndent -1
    , textnl "}"
    ]

rootRoled : ParseEnvironment -> String -> Dict String CodeBlock 
    -> List String -> Source -> Source -> (CodeBlock -> Source) 
    -> Source -> Source
rootRoled env key dict vars roleVar header content footer = SMulti
    [ text "public function "
    , text key 
    , text "("
    , SMulti
        <| List.intersperse (text ", ")
        <| List.map 
            (\v -> SMulti
                [ text "$"
                , text v
                ]
            )
        <| vars
    , textnl ") {"
    , SIndent 1
    , header
    , if Dict.isEmpty dict
        then SNone 
        else SMulti
            [ text "switch ("
            , roleVar
            , textnl ") {"
            , SIndent 1
            , SMulti 
                <| List.map 
                    (\(k,block) -> SMulti
                        [ text "case '"
                        , text k
                        , textnl "': {"
                        , SIndent 1
                        , content block
                        , SIndent -1
                        , textnl "} break;"
                        ]
                    )
                <| Dict.toList dict
            , SIndent -1
            , textnl "}"
            ]
    , footer
    , SIndent -1
    , textnl "}"
    ]

rootRoomName : ParseEnvironment -> String -> Dict (String,String) CodeBlock 
    -> List String -> Source -> Source -> Source -> (CodeBlock -> Source) 
    -> Source -> Source
rootRoomName env key dict vars chatVar votVar header content footer = SMulti
    [ text "public function "
    , text key 
    , text "("
    , SMulti
        <| List.intersperse (text ", ")
        <| List.map 
            (\v -> SMulti
                [ text "$"
                , text v
                ]
            )
        <| vars
    , textnl ") {"
    , SIndent 1
    , header
    , if Dict.isEmpty dict 
        then SNone
        else SMulti
            [ text "switch ("
            , chatVar
            , textnl ") {"
            , SIndent 1
            , SMulti 
                <| List.map 
                    (\(k,d) -> SMulti
                        [ text "case '"
                        , text k
                        , textnl "': "
                        , SIndent 1
                        , text "switch ("
                        , votVar
                        , textnl ") {"
                        , SIndent 1 
                        , SMulti
                            <| List.map 
                                (\(k2,block) -> SMulti 
                                    [ text "case '"
                                    , text k2
                                    , textnl "': {"
                                    , SIndent 1
                                    , content block
                                    , SIndent -1
                                    , textnl "} break;"
                                    ]
                                )
                            <| Dict.toList d
                        , SIndent -1
                        , textnl "}"
                        , textnl "break;"
                        , SIndent -1
                        ]
                    )
                <| Dict.toList
                <| List.foldl 
                    (\((k1, k2), v) d -> Dict.update k1 
                        ( Maybe.withDefault Dict.empty 
                            >> Dict.insert k2 v 
                            >> Just
                        )
                        d
                    )
                    Dict.empty
                <| Dict.toList dict
            , SIndent -1
            , textnl "}"
            ]
    , footer
    , SIndent -1
    , textnl "}"
    ]

outCodeBlock : ParseEnvironment -> CodeBlock -> Source -> Source
outCodeBlock env block header = SMulti
    [ header
    , SMulti
        <| List.map (outCodeElement env False)
        <| block.elements
    , case block.return of 
        Nothing -> SNone 
        Just r -> SMulti
            [ text "return $u_"
            , text r.key
            , textnl ";"
            ]
    ]

outCodeElement : ParseEnvironment -> Bool -> CodeElement -> Source 
outCodeElement env inline element = 
    (\e -> 
        if inline 
        then e 
        else SMulti
            [ e 
            , textnl ";" 
            ]
    )
    <| case element of 
        CESetTo val par -> SMulti 
            [ text "$u_"
            , text par 
            , text " = "
            , outValueInfo env val 
            ]
        CEMath val1 op val2 -> SMulti
            [ outValueInfo env val1
            , text " "
            , text <| case op of 
                MOAdd -> "+"
                MOSub -> "-"
                MOMul -> "*"
                MODiv -> "/"
            , text " "
            , outValueInfo env val2
            ]
        CECompare val1 op val2 -> SMulti
            [ outValueInfo env val1
            , text " "
            , text <| case op of 
                COEq -> "=="
                CONeq -> "!="
                COLt -> "<"
                COLtEq -> "<="
                COGt -> ">"
                COGtEq -> ">="
            , text " "
            , outValueInfo env val2
            ]
        CEBoolOp val1 op val2 -> case op of 
            BOAnd -> SMulti
                [ outValueInfo env val1
                , text " && "
                , outValueInfo env val2
                ]
            BOOr -> SMulti
                [ outValueInfo env val1
                , text " || "
                , outValueInfo env val2
                ]
            BOXor -> SMulti
                [ outValueInfo env val1
                , text " xor "
                , outValueInfo env val2
                ]
            BONand -> SMulti
                [ text "!("
                , outValueInfo env val1
                , text " && "
                , outValueInfo env val2
                , text ")"
                ]
            BOXnor -> SMulti
                [ text "!("
                , outValueInfo env val1
                , text " xor "
                , outValueInfo env val2
                , text ")"
                ]
            BONor -> SMulti
                [ text "!("
                , outValueInfo env val1
                , text " || "
                , outValueInfo env val2
                , text ")"
                ]
        CEConcat val1 val2 -> SMulti
            [ outValueInfo env val1
            , text " . "
            , outValueInfo env val2
            ]
        CEListGet val1 val2 -> SMulti 
            [ if inline
                then SMulti [ SNewLine, SIndent 1 ]
                else SNone
            , textnl "(function ($a, $k) {"
            , SIndent 1
            , textnl "return array_key_exists($k, $a)"
            , SIndent 1
            , textnl "? array('just' => $a[$k])"
            , textnl ": array();"
            , SIndent -2
            , text "})("
            , outValueInfo env val1
            , text ", "
            , outValueInfo env val2
            , text ")"
            , if inline then SIndent -1 else SNone
            ]
        CEDictGet val1 val2 -> outCodeElement env inline 
            <| CEListGet val1 val2
        CETupleFirst val -> SMulti
            [ outValueInfo env val
            , text "[0]"
            ]
        CETupleSecond val -> SMulti
            [ outValueInfo env val
            , text "[1]"
            ]
        CEUnwrapMaybe val block1 block2 -> SMulti
            [ text "$tmp = "
            , outValueInfo env val 
            , textnl ";"
            , textnl "if (isset($tmp['just'])) {"
            , SIndent 1
            , outCodeBlock env block1 
                <| SMulti
                    [ text "$u_"
                    , text <| getMethodArg block1 0 "value"
                    , textnl " = $tmp['just'];"
                    ]
            , SIndent -1
            , textnl "} else {"
            , SIndent 1
            , outCodeBlock env block2 SNone
            , SIndent -1 
            , text "}"
            ]
        CEIf val block1 block2 -> SMulti
            [ text "if ("
            , outValueInfo env val 
            , textnl ") {"
            , SIndent 1
            , outCodeBlock env block1 SNone
            , SIndent -1
            , textnl "} else {"
            , SIndent 1
            , outCodeBlock env block2 SNone 
            , SIndent -1
            , text "}"
            ]
        CEFor val1 val2 val3 block -> SMulti
            [ text "$for_step_"
            , text <| String.fromInt env.level 
            , text " = "
            , outValueInfo env val2
            , textnl ";"
            , text "$for_end_"
            , text <| String.fromInt env.level 
            , text " = "
            , outValueInfo env val3
            , textnl ";"
            , text "for ($i_"
            , text <| String.fromInt env.level 
            , text " = "
            , outValueInfo { env | level = env.level + 1 } val1
            , text "; $for_step_"
            , text <| String.fromInt env.level 
            , text " < 0 ? $i_"
            , text <| String.fromInt env.level 
            , text " >= $for_end_"
            , text <| String.fromInt env.level 
            , text " : $i_"
            , text <| String.fromInt env.level 
            , text " <= $for_end_"
            , text <| String.fromInt env.level 
            , text "; $i_"
            , text <| String.fromInt env.level 
            , text " += $for_step_"
            , text <| String.fromInt env.level 
            , textnl ") {"
            , SIndent 1
            , outCodeBlock { env | level = env.level + 1 } block 
                <| SMulti
                    [ text "$u_"
                    , text <| getMethodArg block 0 "i"
                    , text " = $i_"
                    , text <| String.fromInt env.level 
                    , textnl ";"
                    ]
            , SIndent -1
            , text "}"
            ]
        CEWhile val block -> SMulti
            [ text "while ("
            , outValueInfo env val
            , textnl ") {"
            , SIndent 1
            , outCodeBlock env block SNone
            , SIndent -1
            , text "}"
            ]
        CEBreak -> text "break"
        CEForeachList val block -> SMulti
            [ text "$fl_"
            , text <| String.fromInt env.level 
            , text " = "
            , outValueInfo env val 
            , textnl ";"
            , text "foreach ($fl_"
            , text <| String.fromInt env.level 
            , text " as $u_"
            , text <| getMethodArg block 0 "element"
            , textnl ") {"
            , SIndent 1
            , outCodeBlock { env | level = env.level + 1} block SNone 
            , SIndent -1
            , text "}"
            ]
        CEForeachDict val block -> SMulti
            [ text "$fl_"
            , text <| String.fromInt env.level 
            , text " = "
            , outValueInfo env val 
            , textnl ";"
            , text "foreach ($fl_"
            , text <| String.fromInt env.level 
            , text " as $u_"
            , text <| getMethodArg block 0 "key"
            , text " => $u_"
            , text <| getMethodArg block 1 "element"
            , textnl ") {"
            , SIndent 1
            , outCodeBlock { env | level = env.level + 1} block SNone 
            , SIndent -1
            , text "}"
            ]
        CEEndGame -> text "$this->endGame()"
        CEJust val -> SMulti
            [ text "array('just' => "
            , outValueInfo env val 
            , text ")"
            ]
        CENothing -> text "array()"
        CEList list -> SMulti
            [ textnl "array("
            , SIndent 1
            , SMulti
                <| List.intersperse (textnl ",")
                <| List.map (outValueInfo env)
                <| list
            , if List.isEmpty list then SNone else SNewLine
            , SIndent -1
            , text ")"
            ]
        CEPut par val -> SMulti
            [ text "$u_"
            , text par 
            , text " []= "
            , outValueInfo env val
            ]
        CEGetPlayer val1 val2 ->
            callOwnFunc env "GetPlayer"
                [ val1, val2 ]
        CESetRoomPermission val1 val2 val3 val4 -> 
            callOwnFunc env "setRoomPermission"
                [ val1, val2, val3, val4 ]
        CEInformVoting val1 val2 val3 ->
            callOwnFunc env "informVoting"
                [ val1, val2, val3 ]
        CEAddRoleVisibility val1 val2 val3 ->
            callOwnFunc env "addRoleVisibility"
                [ val1, val2, val3 ]
        CEFilterTopScore val ->
            callOwnFunc env "filterTopScore"
                [ val ]
        CEFilterPlayer val1 val2 val3 ->
            callOwnFunc env "filterPlayer"
                [ val1, val2, val3 ]
        CEPlayerId val -> SMulti
            [ outValueInfo env val
            , text "->id"
            ]
        CEPlayerAlive val -> SMulti
            [ outValueInfo env val
            , text "->alive"
            ]
        CEPlayerExtraWolfLive val -> SMulti
            [ outValueInfo env val 
            , text "->extraWolfLive"
            ]
        CEPlayerHasRole val1 val2 -> SMulti
            [ outValueInfo env val1
            , text "->hasRole("
            , outValueInfo env val2
            , text ")"
            ]
        CEPlayerAddRole val1 val2 -> SMulti
            [ outValueInfo env val1
            , text "->addRole("
            , outValueInfo env val2
            , text ")"
            ]
        CEPlayerRemoveRole val1 val2 -> SMulti
            [ outValueInfo env val1
            , text "->removeRole("
            , outValueInfo env val2
            , text ")"
            ]

callOwnFunc : ParseEnvironment -> String -> List ValueInfo -> Source 
callOwnFunc env name vals = SMulti
    [ text "$this->"
    , text name 
    , text "("
    , SMulti
        <| List.intersperse (text ", ")
        <| List.map (outValueInfo env)
        <| vals
    , text ")"
    ]

outValueInfo : ParseEnvironment -> ValueInfo -> Source 
outValueInfo env info = case info.input of 
    VIEmpty -> text "null"
    VIValue (VDInt v) -> text <| String.fromInt v 
    VIValue (VDFloat v) -> text <| String.fromFloat v 
    VIValue (VDString v) -> text <| JE.encode 0 <| JE.string v 
    VIValue (VDBool v) -> bool v 
    VIValue (VDRoleKey v) -> text <| "'" ++ v ++ "'"
    VIValue (VDPhaseKey v) -> text <| "'" ++ v ++ "'"
    VIValue (VDChatKey v) -> text <| "'" ++ v ++ "'"
    VIValue (VDVotingKey v) -> text <| "'" ++ v ++ "'"
    VIVariable v -> text <| "$u_" ++ v 
    VIBlock v -> SMulti
        [ text "("
        , outCodeElement env True v
        , text ")"
        ]
    
