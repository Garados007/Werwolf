module Dashboard.Test exposing (..)

-- case study for drag&drop

import Html exposing (Html, text, div)
import Html.Attributes as HA exposing (class, style)
import Html.Events as HE exposing (onClick)
import Browser
import DnD

type Node = Node String (List Node)

type alias Path = List Int

type alias Dragger = DnD.Draggable Path Path

type alias Dummy = (Int, String, Maybe Bool)

type alias Model = 
    { nodes : List Node 
    , dragControler : Dragger
    , next : Int
    }

type Msg 
    = Add
    | Remove Path 
    | SetText Path String
    | Move Path Path 
    | WrapDragControler (DnD.Msg Path Path)

main = Browser.element
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }

dnd = DnD.init WrapDragControler Move 

init : () -> (Model, Cmd Msg)
init _ =
    ( Model [] dnd.model 1
    , Cmd.none 
    )

view : Model -> Html Msg 
view model = div 
    [ style "display" "flex"
    , style "flex-direction" "column"
    ]
    [ div 
        [ style "text-align" "center"
        , style "padding" "0.5em"
        , style "border" "1px solid black"
        , style "cursor" "pointer"
        , style "margin-bottom" "0.5em"
        , HE.onClick Add
        ]
        [ text "add" ]
    , div []
        <| viewNodeContainer model.dragControler [] model.nodes
    , DnD.dragged
        model.dragControler
        (\path -> case getNode model.nodes path of 
            Just n -> viewNode dnd.model path n 
            Nothing -> text ""
        )
    ]

getNode : List Node -> Path -> Maybe Node 
getNode nodes path = case path of 
    [] -> Nothing
    p::[] -> nodes 
        |> List.indexedMap Tuple.pair 
        |> List.filter (Tuple.first >> (==) p)
        |> List.head
        |> Maybe.map Tuple.second
    p::ps -> nodes
        |> List.indexedMap Tuple.pair 
        |> List.filter (Tuple.first >> (==) p)
        |> List.head 
        |> Maybe.andThen (\(_, Node _ nl) -> getNode nl ps)

insertNode : Node -> Path -> Node -> Node 
insertNode root path node = case path of 
    [] -> node 
    p::[] -> case root of 
        Node rt rl -> Node rt 
            <| List.take p rl 
            ++ [ node ]
            ++ List.drop p rl 
    p::ps -> case root of 
        Node rt rl -> Node rt 
            <| List.indexedMap
                (\ind nr ->
                    if ind == p
                    then insertNode nr ps node 
                    else nr
                )
            <| rl

viewNode : Dragger -> Path -> Node -> Html Msg 
viewNode dragger path (Node nt sn) = div 
    [ style "border" "1px solid black"
    , style "background-color" 
        <| case DnD.getDragMeta dragger of 
            Just dp -> 
                if dp == path 
                then "gray"
                else "white"
            Nothing -> "white"
    ]
    [ div
        [ style "border-bottom" "1px solid black" 
        , style "display" "flex" 
        ]
        [ dnd.draggable path
            [ style "padding" "0.5em" 
            , style "cursor" "move"
            ] 
            [ text "Node" ]
        , Html.input 
            [ HA.type_ "text" 
            , HA.value nt
            , HE.onInput <| SetText path
            , style "box-sizing" "border-box"
            , style "flex-grow" "1"
            , style "border" "none"
            , style "border-left" "1px solid black"
            , style "border-right" "1px solid black"
            , style "padding" "0.5em"
            , style "background-color" "transparent"
            ]
            []
        , div 
            [ style "padding" "0.5em" 
            , style "cursor" "pointer"
            , HE.onClick <| Remove path
            ]
            [ text "remove" ]
        ]
    , div
        [ style "padding" "0.5em"
        ]
        <| viewNodeContainer dragger path sn
    ]

viewNodeContainer : Dragger -> Path -> List Node -> List (Html Msg)
viewNodeContainer dragger root list = 
    let dropper : Int -> Html Msg 
        dropper index = 
            let dpath = root ++ [index]
                focus : Bool 
                focus = case DnD.getDropMeta dragger of 
                    Just dp -> (&&) (dp == dpath)
                        <| case DnD.getDragMeta dragger of 
                            Just sp -> not <| isPrefix sp dp 
                            Nothing -> True
                    Nothing -> False
            in dnd.droppable
                dpath
                [ style "height" 
                    <| if focus then "2em" else "1em"
                , style "background-color"
                    <| if focus then "yellow" else "transparent"
                ]
                []
        mixin : Int -> Node -> List (Html Msg)
        mixin index node = 
            [ viewNode dragger (root ++ [index]) node 
            , dropper <| index + 1
            ]        
    in list 
        |> List.indexedMap mixin
        |> List.concat
        |> (::) (dropper 0)
    
update : Msg -> Model -> (Model, Cmd Msg)
update msg model = case msg of 
    Add -> Tuple.pair
        { model 
        | nodes = model.nodes ++ 
            [ Node ("new item " ++ String.fromInt model.next)
                [] 
            ]
        , next = model.next + 1
        }
        Cmd.none
    Remove path -> Tuple.pair
        { model
        | nodes = case remove path (Node "" model.nodes) of 
            Node _ nodes -> nodes
        }
        Cmd.none
    SetText path text -> Tuple.pair 
        { model 
        | nodes = case setText path text (Node "" model.nodes) of 
            Node _ nodes -> nodes 
        }
        Cmd.none
    Move target source -> Tuple.pair 
        { model 
        | nodes =
            if isPrefix source target
            then model.nodes
            else move source target model.nodes 
        }
        Cmd.none
    WrapDragControler smsg ->
        ( { model | dragControler = DnD.update smsg model.dragControler }
        , Cmd.none 
        )

remove : Path -> Node -> Node 
remove path (Node nt sn) = case path of 
    [] -> (Node nt sn)
    p::[] -> Node nt 
        <| List.map Tuple.second
        <| List.filter (Tuple.first >> (/=) p)
        <| List.indexedMap Tuple.pair
        <| sn
    p::ps -> Node nt 
        <| List.indexedMap
            (\ind subNode ->
                if ind == p 
                then remove ps subNode 
                else subNode
            )
        <| sn

setText : Path -> String -> Node -> Node 
setText path text (Node nt sn) = case path of 
    [] -> (Node text sn)
    p::ps -> Node nt 
        <| List.indexedMap
            (\ind subNode ->
                if ind == p 
                then setText ps text subNode
                else subNode 
            )
        <| sn 

moveDirect : Int -> Int -> List a -> List a 
moveDirect s t list =
    if s == t 
    then list 
    else if s < t -- [0, 1, 2] [s=3] [4, 5] [t=6] [6, 7]
    then List.take s list 
        ++ (List.take t list |> List.drop (s + 1))
        ++ (List.take (s + 1) list |> List.drop s)
        ++ List.drop t list
    else -- [0, 1, 2] [t=3] [3, 4] [s=5] [6, 7]
        List.take t list 
        ++ (List.take (s + 1) list |> List.drop s)
        ++ (List.take s list |> List.drop t)
        ++ List.drop (s + 1) list

move : Path -> Path -> List Node -> List Node 
move source target list = case (source, target) of 
    ([], _) -> list
    (_, []) -> list
    (s::[], t::[]) -> moveDirect s t list
    (s::[], t::ts) -> case getNode list source of 
        Just rn -> list
            |> List.indexedMap
                (\ind mn ->
                    if ind == t 
                    then insertNode mn ts rn 
                    else mn 
                )
            |> \l -> List.take s l ++ List.drop (s + 1) l
        Nothing -> list
    (s::ss, t::[]) -> case getNode list source of 
        Just rn -> list
            |> List.indexedMap
                (\ind mn ->
                    if ind == s 
                    then remove ss mn 
                    else mn 
                )
            |> \l -> List.take t l ++ [ rn ] ++ List.drop t l
        Nothing -> list
    (s::ss, t::ts) ->
        if s == t
        then List.indexedMap
            (\ind (Node nt nl) -> Node nt 
                <| if ind == s 
                    then move ss ts nl 
                    else nl
            )
            list
        else case getNode list (s::ss) of 
            Just rn -> List.indexedMap
                (\ind mn ->
                    if ind == s 
                    then remove ss mn 
                    else if ind == t 
                    then insertNode mn ts rn 
                    else mn
                )
                list 
            Nothing -> list

isPrefix : Path -> Path -> Bool 
isPrefix prefix full = case (prefix, full) of 
    ([], []) -> False -- real prefix 
    (_::_, []) -> False
    ([], _::_) -> True
    (a::aa, b::bb) ->
        if a == b 
        then isPrefix aa bb
        else False

subscriptions : Model -> Sub Msg
subscriptions model = dnd.subscriptions model.dragControler