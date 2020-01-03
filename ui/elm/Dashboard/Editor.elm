module Dashboard.Editor exposing (..)

import Dashboard.Editor.Logic exposing (..)
import Dashboard.Editor.Logic.Converter as Conv
import Dashboard.Editor.View exposing (..)
import Dashboard.Editor.Token exposing (codeEnvironment)
import Dashboard.Environment exposing (Environment)
import Dashboard.Source as Source
import Dashboard.Util.Html exposing (..)

import Html exposing (Html, div, text)
import Html.Attributes as HA exposing (class)
import Html.Events as HE
import Set exposing (Set)
import Dict exposing (Dict)
import Config exposing (uri_host,uri_path)
import List.Extra as LE
import Browser
import Browser.Dom
import Task
import Json.Encode as JE
import DnD


main : Platform.Program () Editor EditorMsg
main = Browser.element
    { init = \() -> (init "role1", Cmd.none)
    , view = \model -> div []
        [ view Dashboard.Environment.test model
        , dashboardStylesheet "editor-view"
        ]
    , update = \msg model -> update Dashboard.Environment.test msg model 
        |> \(m, c, _) -> (m, c)
    , subscriptions = subscriptions
    }

type alias Editor =
    { viewMode : EditorViewMode
    , code : CodeEnvironment
    , addBox : Maybe EditorAddBox
    , openError : Maybe (CodeEnvironmentPath (List Int))
    , closed : List (CodeEnvironmentPath (List Int))
    , selCodeHead : Dict String (List String)
    , errors : Dict (List String) ErrorNode
    , dragger : DnD.Draggable 
        (CodeEnvironmentPath (List Int))
        (CodeEnvironmentPath (List Int))
    , roleKey : String
    }

type alias EditorAddBox = 
    { path : CodeEnvironmentPath (List Int)
    , type_ : TypeInfo
    , filter : String
    , category : Maybe CodeCategory
    , details : Maybe String
    }

type EditorViewMode 
    = CodeEditor
    | SourceView
    | PhpView

type EditorMsg
    = NoOp
    -- View Mode Msg
    | ChangeViewMode EditorViewMode
    -- Add Box Msgs
    | SetAddBox EditorAddBox
    | ConfirmAddBox CodeElement
    | ClearAddBox
    -- Code environment 
    | SetCENewFilter String (List String)
    | AddCodeBlock String
    | AddClipboard
    | RemoveCodeBlock (CodeEnvironmentPath ())
    -- Code Blocks
    | ViewCodeAdder (CodeEnvironmentPath (List Int)) TypeInfo
    | CBChanged (CodeEnvironmentPath (List Int)) CodeEditEntry
    | ViewError (CodeEnvironmentPath (List Int)) Bool
    | CBClosed (CodeEnvironmentPath (List Int)) Bool
    | CBRemove (CodeEnvironmentPath (List Int))
    -- Drag Events
    | WrapDragger
        (DnD.Msg 
            (CodeEnvironmentPath (List Int))
            (CodeEnvironmentPath (List Int))
        )
    | Move (CodeEnvironmentPath (List Int)) (CodeEnvironmentPath (List Int))

type EditorEvent 
    = CodeChanged CodeEnvironment

dnd = DnD.init WrapDragger Move

init : String -> Editor 
init roleKey = 
    { viewMode = CodeEditor
    , code = newCodeEnvironment
    , addBox = Nothing
    , openError = Nothing
    , closed = []
    , selCodeHead = Dict.empty
    , errors = Dict.empty
    , dragger = dnd.model
    , roleKey = roleKey
    }

initCode : CodeEnvironment -> Editor -> Editor 
initCode code editor = { editor | code = code }

getVarEnvironment : Environment -> VarEnvironment
getVarEnvironment environment =
    { vars = Dict.empty
    , chatKey = environment.keys.chatKeys
    , phaseKey = environment.keys.phaseKeys
    , roleKey = environment.keys.roleKeys
    , votingKey = environment.keys.votingKeys
    }

update : Environment -> EditorMsg -> Editor -> (Editor, Cmd EditorMsg, List EditorEvent)
update environment msg editor =
    let neditor = updateInternal environment msg editor
        (ncode, nerrors) = mapCodeOutside
            (\path cb -> 
                let (ne, ve, en) = checkBlockValidity
                        cb (getVarEnvironment environment)
                in (ne, (path, en))
            )
            neditor.code
        cmds = case msg of
            ViewCodeAdder _ _ -> Task.attempt (always NoOp)
                <| Browser.Dom.focus "new-entry-box-search-box"
            _ -> Cmd.none
        tasks = case msg of 
            ConfirmAddBox _ -> [ CodeChanged ncode ]
            AddCodeBlock _ -> [ CodeChanged ncode ]
            AddClipboard -> [ CodeChanged ncode ]
            RemoveCodeBlock _ -> [ CodeChanged ncode ]
            CBChanged _ _ -> [ CodeChanged ncode ]
            CBRemove _ -> [ CodeChanged ncode ]
            Move _ _ -> [ CodeChanged ncode ]
            _ -> []
    in tripel
        { neditor
        | code = ncode
        , errors = nerrors
            |> List.filter 
                (\(_, ErrorNode e) -> not
                    <| List.isEmpty e.errors
                    && Dict.isEmpty e.nodes
                )
            |> Dict.fromList 
        }
        cmds
        tasks
        
tripel : a -> b -> c -> (a, b, c)
tripel a b c = (a, b, c)
    
updateInternal : Environment -> EditorMsg -> Editor -> Editor 
updateInternal environment msg editor = case msg of 
    NoOp -> editor
    ChangeViewMode mode -> { editor | viewMode = mode }
    SetAddBox box -> { editor | addBox = Just box }
    ConfirmAddBox element -> case editor.addBox of
        Just box ->
            { editor 
            | code = addCodeBlock 
                (getVarEnvironment environment) 
                element 
                box.path 
                editor.code
            , addBox = Nothing
            , openError = Nothing
            , closed = List.map 
                (\path -> 
                    if getCEBlock path == getCEBlock box.path
                    then setCEPath
                        (injectPath
                            (getCEPath box.path)
                            (getCEPath path)
                        )
                        path
                    else path
                )
                editor.closed
            }
        Nothing -> editor
    ClearAddBox -> { editor | addBox = Nothing }
    SetCENewFilter name filter -> 
        { editor
        | selCodeHead = Dict.insert name filter editor.selCodeHead
        }
    AddCodeBlock name ->
        { editor 
        | code = addEmptyCodeEnvironment
            name 
            (Dict.get name editor.selCodeHead |> Maybe.withDefault [])
            editor.code
        , selCodeHead = Dict.remove name editor.selCodeHead
        }
    AddClipboard ->
        { editor 
        | code = addClipboard editor.code
        }
    RemoveCodeBlock path ->
        { editor
        | code = removeRootCodeBlock path editor.code
        , openError = Nothing
        , closed = List.filter 
            ((==) (getCEBlock path)
                << getCEBlock
            )
            editor.closed
        }
    ViewCodeAdder path type_ ->
        { editor 
        | addBox = Just
            { path = path
            , type_ = type_
            , filter = ""
            , category = Nothing
            , details = Nothing
            }
        }
    CBChanged path edit ->
        { editor 
        | code = mapCodeEnvironment
            (\spath block -> case spath of 
                [] -> case edit of
                    CEEBlock _ nb -> nb 
                    _ -> block
                p::ps -> 
                    { block
                    | elements = LE.updateAt p 
                        ( deepEdit
                            (getVarEnvironment environment)
                            ps 
                            edit 
                        )
                        block.elements
                    }
            )
            path
            editor.code
        }
    ViewError path should ->
        { editor
        | openError = 
            if should 
            then Just path
            else Nothing
        }
    CBClosed path should ->
        { editor 
        | closed =
            if should
            then if List.member path editor.closed
                then editor.closed
                else path::editor.closed
            else LE.remove path editor.closed
        }
    CBRemove path ->
        { editor 
        | code = mapCodeEnvironment 
            (\spath block -> case spath of 
                [] -> block
                p::ps ->
                    { block 
                    | elements = List.filterMap 
                            (\(ind, elem) ->
                                if ind /= p 
                                then Just elem 
                                else deepDelete 
                                    (getVarEnvironment environment)
                                    ps 
                                    elem
                            )
                        <| List.indexedMap Tuple.pair
                        <| block.elements
                    }
            )
            path 
            editor.code
        , addBox = Nothing
        , openError = Nothing
        , closed = List.map 
            (\spath -> 
                if getCEBlock spath == getCEBlock path
                then setCEPath
                    (removePath
                        (getCEPath path)
                        (getCEPath spath)
                    )
                    spath
                else spath
            )
            editor.closed
        }
    WrapDragger smsg ->
        { editor 
        | dragger = DnD.update smsg editor.dragger
        }
    Move target source ->
        case getCodeElement
            (getVarEnvironment environment)
            editor.code 
            source 
        of 
            Nothing -> editor 
            Just se ->
                let ntarget = 
                        if getCEBlock source == getCEBlock target
                        then setCEPath 
                            (removePath (getCEPath source) (getCEPath target))
                            target
                        else target
                    spl = List.length <| getCEPath source
                in  { editor 
                    | code = editor.code
                        |> removeCodeBlock 
                            (getVarEnvironment environment) 
                            source
                        |> addCodeBlock
                            (getVarEnvironment environment)
                            se
                            ntarget
                    , openError = Nothing
                    , closed = 
                        ( List.map 
                            (\path -> 
                                if getCEBlock path == getCEBlock source
                                then setCEPath
                                    (removePath
                                        (getCEPath source)
                                        (getCEPath path)
                                    )
                                    path
                                else if getCEBlock path == getCEBlock ntarget
                                then setCEPath
                                    (injectPath
                                        (getCEPath ntarget)
                                        (getCEPath path)
                                    )
                                    path
                                else path
                            )
                            editor.closed
                        ) ++
                        ( editor.closed 
                            |> List.filter 
                                (\path -> getCEBlock source == getCEBlock path
                                    && getCEPath source ==
                                        ( getCEPath path 
                                            |> List.take spl
                                        )
                                )
                            |> List.map 
                                (\path -> setCEPath
                                    ( (++) (getCEPath ntarget)
                                        <| List.drop spl
                                        <| getCEPath path
                                    )
                                    ntarget
                                )
                        )
                    }

removeCodeBlock : VarEnvironment -> CodeEnvironmentPath (List Int) -> CodeEnvironment -> CodeEnvironment 
removeCodeBlock vars = mapCodeEnvironment 
    (\p cb -> case p of 
        [] -> cb 
        p1::[] ->
            { cb | elements = LE.removeAt p1 cb.elements }
        p1::pl ->
            { cb 
            | elements = cb.elements
                |> List.indexedMap Tuple.pair 
                |> List.filterMap 
                    (\(ind, e) ->
                        if ind == p1 
                        then deepDelete vars pl e 
                        else Just e
                    )
            }
    )

addCodeBlock : VarEnvironment -> CodeElement -> CodeEnvironmentPath (List Int) -> CodeEnvironment -> CodeEnvironment
addCodeBlock vars element = mapCodeEnvironment
    (\p cb -> case p of 
        [] -> { cb | elements = cb.elements ++ [ element ] }
        p1::[] -> 
            { cb 
            | elements = List.take p1 cb.elements 
                ++ [ element ]
                ++ List.drop p1 cb.elements
            }
        p1::pl ->
            { cb 
            | elements = LE.updateAt p1 
                (deepAdd vars pl element)
                cb.elements
            }
    )

mapCodeOutside : (List String -> CodeBlock -> (CodeBlock, a)) -> CodeEnvironment -> (CodeEnvironment, List a)
mapCodeOutside func env = Dict.foldl 
    (\k rv (oenv, olist) -> case rv of 
        CEBTDirect cb ->
            let (ncb, nl) = func [k] cb
            in  Tuple.pair 
                { oenv 
                | blocks = Dict.insert k 
                    (CEBTDirect ncb)
                    oenv.blocks
                }
                (nl::olist)
        CEBTPhased new dict ->
            let (nd, nl) = Dict.foldl 
                    (\dk cb (id, il) ->
                        let (ncb, nil) = func [k, dk] cb 
                        in Tuple.pair 
                            (Dict.insert dk ncb id)
                            (nil :: il)
                    )
                    (dict, olist)
                    dict
            in Tuple.pair 
                { oenv
                | blocks = Dict.insert k 
                    (CEBTPhased new nd)
                    oenv.blocks
                }
                (nl ++ olist)
        CEBTRoled new dict ->
            let (nd, nl) = Dict.foldl 
                    (\dk cb (id, il) ->
                        let (ncb, nil) = func [k, dk] cb 
                        in Tuple.pair 
                            (Dict.insert dk ncb id)
                            (nil :: il)
                    )
                    (dict, olist)
                    dict
            in Tuple.pair 
                { oenv
                | blocks = Dict.insert k 
                    (CEBTRoled new nd)
                    oenv.blocks
                }
                (nl ++ olist)
        CEBTRoomName new dict ->
            let (nd, nl) = Dict.foldl 
                    (\(dk1,dk2) cb (id, il) ->
                        let (ncb, nil) = func [k, dk1, dk2] cb 
                        in Tuple.pair 
                            (Dict.insert (dk1,dk2) ncb id)
                            (nil :: il)
                    )
                    (dict, olist)
                    dict
            in Tuple.pair 
                { oenv
                | blocks = Dict.insert k 
                    (CEBTRoomName new nd)
                    oenv.blocks
                }
                (nl ++ olist)
    )
    (env, [])
    env.blocks

getCodeElement : VarEnvironment -> CodeEnvironment -> CodeEnvironmentPath (List Int) -> Maybe CodeElement
getCodeElement vars code path = 
    let rootInfo : Maybe (List Int, CodeElement)
        rootInfo = case path of 
            CEPBlocks (rk::rbp) (bp::sp) -> code.blocks
                |> Dict.get rk 
                |> Maybe.andThen
                    (\cebt -> case (cebt, rbp) of 
                        (CEBTDirect cb, _) -> Just cb
                        (CEBTPhased _ d, lk::_) -> Dict.get lk d 
                        (CEBTRoled _ d, lk::_) -> Dict.get lk d 
                        (CEBTRoomName _ d, lk1::lk2::_) -> Dict.get (lk1, lk2) d 
                        _ -> Nothing
                    )
                |> Maybe.map .elements 
                |> Maybe.withDefault []
                |> LE.getAt bp
                |> Maybe.map (Tuple.pair sp) 
            CEPClipboard ind (bp::sp) -> code.clipboard
                |> LE.getAt ind 
                |> Maybe.map .elements
                |> Maybe.withDefault []
                |> LE.getAt bp 
                |> Maybe.map (Tuple.pair sp)
            _ -> Nothing
    in Maybe.andThen 
        (\(spath, ce) -> deepGet vars spath ce)
        rootInfo

view : Environment -> Editor -> Html EditorMsg
view environment editor = div [ class "code-editor" ]
    [ div [ class "view-mode-selector" ]
        <| List.map 
            (\(vm,txt) -> div 
                [ HA.classList
                    [ Tuple.pair "button" True 
                    , Tuple.pair "selected"
                        <| vm == editor.viewMode
                    ]
                , HE.onClick <| ChangeViewMode vm
                ]
                [ text txt ]
            )
        <|  [ Tuple.pair CodeEditor "Editor"
            , Tuple.pair SourceView "View Source"
            , Tuple.pair PhpView "View PHP Target"
            ]
    , case editor.viewMode of 
        CodeEditor -> viewCodeEditor environment editor
        SourceView -> Html.pre []
            <| List.singleton 
            <| Html.code
                [ class "language-json" ]
            <| List.singleton
            <| text 
            <| JE.encode 2
            <| Conv.encodeCodeEnvironment
            <| editor.code
        PhpView -> Html.pre []
            <| List.singleton
            <| Html.code 
                [ class "language-php" ]
            <| List.singleton
            <| text 
            <| Source.build 4
            <| Maybe.withDefault Source.SNone
            <| Maybe.map 
                (\r -> codeEnvironment
                    { global = environment 
                    , code = editor.code
                    , role = r
                    , level = 0
                    }
                )
            <| Dict.get editor.roleKey environment.roles
    ]   

viewCodeEditor : Environment -> Editor -> Html EditorMsg
viewCodeEditor environment editor = div [ class "code-editor-container" ]
    [ viewCodeEnvironment
        editor.errors
        (getVarEnvironment environment)
        editor
    , case editor.addBox of 
        Nothing -> text ""
        Just box -> div 
            [ class "new-entry-frame" ]
            [ div 
                [ class "background" 
                , HE.onClick ClearAddBox
                ] []
            , viewNewEntryBox
                ConfirmAddBox
                (\v -> SetAddBox { box | filter = v })
                (\v -> SetAddBox { box | category = v })
                (\v -> SetAddBox { box | details = v })
                (getVarEnvironment environment)
                box.filter
                box.category
                box.details
                box.type_
            ]
    , DnD.dragged editor.dragger
        <| \path -> Maybe.withDefault (text "")
            <| Maybe.map (viewCodePreview (getVarEnvironment environment))
            <| getCodeElement (getVarEnvironment environment) editor.code path
    ]

viewCodeEnvironment : Dict (List String) ErrorNode 
    -> VarEnvironment
    -> Editor
    -> Html EditorMsg
viewCodeEnvironment nodes vars editor = 
    let viewRegionedCode : String -> List (List String) -> List (List String, CodeBlock) -> Html EditorMsg
        viewRegionedCode name posibles blocks = div 
            [ class <| "code-section-container " ++ name ]
            [ div [ class "code-section-header" ]
                [ text name ]
            , div [ class "code-section-adder" ]
                [ div [ class "selects" ]
                    <| List.map (div [] << List.singleton)
                    <| List.indexedMap
                        (\ind list -> 
                            let filter = Dict.get name editor.selCodeHead
                                    |> Maybe.withDefault []
                            in Html.select 
                                [ HE.onInput 
                                    <| \val -> SetCENewFilter name
                                    <| LE.setAt ind val
                                    <| Maybe.withDefault 
                                        (List.repeat (List.length posibles) "")
                                    <| Dict.get name editor.selCodeHead
                                ]
                                <| List.map 
                                    (\v -> Html.option 
                                        [ HA.value v 
                                        , HA.disabled 
                                            <| (&&) (v == "")
                                            <| not 
                                            <| (==) ""
                                            <| Maybe.withDefault ""
                                            <| LE.getAt ind
                                            <| filter
                                        , HA.selected 
                                            <| (==) v 
                                            <| Maybe.withDefault ""
                                            <| LE.getAt ind
                                            <| filter
                                        ]
                                        [ text <| 
                                            if v == ""
                                            then "--select--"
                                            else v 
                                        ]
                                    )
                                <| "" :: list
                        )
                    <| posibles
                , if  (\f -> List.any ((==) f << Just << Tuple.first) blocks)
                        <| Dict.get name editor.selCodeHead
                    then div [ class "exists" ]
                        [ text "block already exists" ]
                    else if Dict.get name editor.selCodeHead
                            |> Maybe.withDefault [ "" ]
                            |> List.any ((==) "")
                    then text ""
                    else div 
                        [ class "add" 
                        , HE.onClick <| AddCodeBlock name
                        ]
                        [ text "Add" ]
                ]
            , div [ class "code-section-body" ]
                <| List.map 
                    (\(path, block) -> viewRootCodeBlock
                        editor
                        (CEPBlocks <| name::path)
                        (Dict.get (name::path) nodes)
                        vars 
                        ( String.concat 
                            <| List.intersperse " > "
                            <| name :: path
                        )
                        block
                    )
                <| blocks
            ] 
    in div 
        [ class "code-environment" ]
        [ div [ class "code-section" ]
            <| List.map
                (\(name, envBlock) -> case envBlock of  
                    CEBTDirect block -> viewRegionedCode
                        name 
                        []
                        [ ([], block) ]
                    CEBTPhased _ dict -> viewRegionedCode
                        name 
                        [ Set.toList vars.phaseKey ]
                        <| List.map (Tuple.mapFirst List.singleton)
                        <| Dict.toList dict
                    CEBTRoled _ dict -> viewRegionedCode
                        name
                        [ Set.toList vars.roleKey ]
                        <| List.map (Tuple.mapFirst List.singleton)
                        <| Dict.toList dict 
                    CEBTRoomName _ dict -> viewRegionedCode
                        name
                        [ Set.toList vars.chatKey
                        , Set.toList vars.votingKey
                        ]
                        <| List.map 
                            (Tuple.mapFirst 
                                (\(v1,v2) -> [v1, v2])
                            )
                        <| Dict.toList dict
                )
            <| Dict.toList editor.code.blocks
        , div [ class "clipboard" ]
            <|  (\l -> (++) l 
                    <| List.singleton
                    <| div 
                        [ class "adder" 
                        , HE.onClick AddClipboard
                        ]
                        [ text "add empty clipboard" ]

                )
            <| List.indexedMap
                (\index block -> viewRootCodeBlock
                    editor
                    (CEPClipboard index)
                    Nothing
                    vars 
                    ((++) "Clipboard #" <| String.fromInt index)
                    block
                )
            <| editor.code.clipboard
        ]

inlineLog : String -> b -> a -> a 
inlineLog info b a = always a <| Debug.log info b

viewRootCodeBlock : Editor
    -> (List Int -> CodeEnvironmentPath (List Int))
    -> Maybe ErrorNode
    -> VarEnvironment 
    -> String 
    -> CodeBlock
    -> Html EditorMsg
viewRootCodeBlock editor path node vars name block = viewCodeBlock 
    { onChange = \spath -> CBChanged (path spath)
    , onViewError = \spath -> ViewError (path spath)
    , onAddBlock = \spath -> ViewCodeAdder (path spath)
    , onClosed = \spath -> CBClosed (path spath)
    , onRemove = \spath -> 
        if spath == []
        then RemoveCodeBlock <| setCEPath () <| path []
        else CBRemove (path spath)
    , viewError = case editor.openError of 
        Nothing -> Set.empty
        Just epath -> 
            if getCEBlock epath /= getCEBlock (path [])
            then Set.empty
            else Set.singleton <| getCEPath epath
    , closedBlocks = Set.fromList 
        <| List.filterMap 
            (\spath ->
                if getCEBlock spath == getCEBlock (path [])
                then Just 
                    <| getCEPath spath
                else Nothing
            )
        <| editor.closed
    , draggable = \spath -> dnd.draggable (path spath)
    , droppable = 
        if DnD.getDragMeta editor.dragger /= Nothing
        then \spath -> dnd.droppable (path spath)
        else \_ -> div
    , currentDrag = 
        if Maybe.map getCEBlock (DnD.getDragMeta editor.dragger) 
            == Just (getCEBlock (path []))
        then Maybe.map getCEPath <| DnD.getDragMeta editor.dragger
        else Nothing
    , currentDrop = 
        if Maybe.map getCEBlock (DnD.getDropMeta editor.dragger) 
            == Just (getCEBlock (path []))
        then Maybe.map getCEPath <| DnD.getDropMeta editor.dragger
        else Nothing
    }
    (Maybe.withDefault 
        (ErrorNode { errors = [], nodes = Dict.empty })
        <| node
    )
    []
    vars
    True
    name
    block

subscriptions : Editor -> Sub EditorMsg
subscriptions editor = dnd.subscriptions editor.dragger