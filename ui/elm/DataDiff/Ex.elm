module DataDiff.Ex exposing
    ( ModActionEx (..)
    , SingleActionEx (..)
    , DetectorEx
    , PathModify 
    , ActionModify
    , value
    , list
    , dict
    , maybe
    , mapPath
    , mapData
    , mapMsg
    , batch
    , execute
    , andThen
    , inline
    , makeEx
    , makeSimple
    , goPath
    )

-- elm/core
import Dict exposing (Dict)

-- local
import DataDiff exposing (..)

type ModActionEx path data msg
    = AddedEx (path -> data -> msg)
    | RemovedEx (path -> data -> msg)

type SingleActionEx path data msg 
    = ChangedEx (path ->data -> data ->  msg)

type DetectorEx path data msg
    = DetectorEx (path -> data -> data -> List msg)

type alias PathModify input output data token =
    input -> data -> data -> token -> output

type alias ActionModify input output token =
    input -> token -> output

value : List (SingleActionEx path data msg) -> DetectorEx path data msg
value mlist = DetectorEx <| \path old new ->
    if old /= new
    then List.concatMap
        (\m -> case m of 
            ChangedEx f -> [ f path old new ]
        )
        mlist
    else []

list : PathModify ipath opath data Int 
    -> ActionModify ipath apath Int
    -> List (ModActionEx apath data msg) 
    -> DetectorEx opath data msg 
    -> DetectorEx ipath (List data) msg 
list pathMod actionMod mlist (DetectorEx det) = DetectorEx <| \path old new ->
    let comp : Int -> List data -> List data -> List msg 
        comp ind l1 l2 = case l1 of 
            [] -> List.concatMap
                (\m -> case m of 
                    AddedEx f -> List.indexedMap
                        (\i e ->
                            f (actionMod path <| ind + i) e
                        )
                        l2
                    _ -> []
                )
                mlist
            l1e :: l1l -> case l2 of 
                [] -> List.concatMap
                    (\m -> case m of 
                        RemovedEx f -> List.indexedMap
                            (\i e ->
                                f (actionMod path <| ind + i) e
                            )
                            l2
                        _ -> []
                    )
                    mlist
                l2e :: l2l -> det (pathMod path l1e l2e ind) l1e l2e
                    ++ comp (ind + 1) l1l l2l
    in comp 0 old new

dict : PathModify ipath opath data comparable 
    -> ActionModify ipath apath comparable
    -> List (ModActionEx apath data msg)
    -> DetectorEx opath data msg
    -> DetectorEx ipath (Dict comparable data) msg
dict pathMod actionMod mlist (DetectorEx det) = DetectorEx 
    <| \path old new -> Dict.merge
        (\k o r -> (++) r 
            <| List.filterMap
                (\m -> case m of 
                    RemovedEx f -> Just
                        <| f (actionMod path k) o
                    _ -> Nothing
                )
                mlist
        )
        (\k o n r -> (++) r 
            <| det (pathMod path o n k) o n
        )
        (\k n r -> (++) r 
            <| List.filterMap
                (\m -> case m of 
                    AddedEx f -> Just
                        <| f (actionMod path k) n
                    _ -> Nothing 
                )
                mlist
        )
        old
        new 
        []

maybe : PathModify ipath opath data () 
    -> List (ModActionEx ipath data msg)
    -> DetectorEx opath data msg 
    -> DetectorEx ipath (Maybe data) msg 
maybe pathMod mlist (DetectorEx det) = DetectorEx 
    <| \path old new -> case old of 
        Just o -> case new of 
            Just n -> det (pathMod path o n ()) o n 
            Nothing -> List.filterMap 
                (\m -> case m of 
                    RemovedEx f -> Just <| f path o
                    _ -> Nothing 
                )
                mlist
        Nothing -> case new of 
            Just n -> List.filterMap
                (\m -> case m of 
                    AddedEx f -> Just <| f path n 
                    _ -> Nothing 
                )
                mlist 
            Nothing -> []

mapPath : (b -> a) -> DetectorEx a data msg -> DetectorEx b data msg 
mapPath func (DetectorEx det) = DetectorEx <| \path old new ->
    det (func path) old new

mapData : (b -> a) -> DetectorEx path a msg -> DetectorEx path b msg 
mapData func (DetectorEx det) = DetectorEx <| \path old new ->
    det path (func old) (func new)

mapMsg : (a -> b) -> DetectorEx path data a -> DetectorEx path data b 
mapMsg func (DetectorEx det) = DetectorEx <| \path old new ->
    List.map func <| det path old new

batch : List (DetectorEx path data msg) -> DetectorEx path data msg 
batch detectors = DetectorEx 
    <| \path old new -> List.concatMap 
        (\(DetectorEx d) -> d path old new)
        detectors 
    
execute : DetectorEx path data msg -> path -> data -> data -> List msg 
execute (DetectorEx det) = det 

andThen : (path -> data -> data -> List msg) -> DetectorEx path data msg 
andThen = DetectorEx

inline : List (SingleActionEx path data msg) 
    -> DetectorEx path data msg 
    -> DetectorEx path data msg 
inline mlist detector = batch
    [ value mlist 
    , detector 
    ]

makeEx : DataDiff.Detector data msg -> DetectorEx path data msg 
makeEx detector = DetectorEx <| \path old new ->
    DataDiff.execute detector old new

makeSimple : path -> DetectorEx path data msg -> DataDiff.Detector data msg
makeSimple path detector = DataDiff.andThen <|
    \old new -> execute detector path old new 

goPath : token 
    -> (data1 -> data2) 
    -> DetectorEx path data2 msg 
    -> DetectorEx (token -> path) data1 msg 
goPath token func detector = mapPath (\f -> f token) 
    <| mapData func detector

-- tests

-- type Msg 
--     = Msg Path

-- type alias A =
--     { va : Maybe Int
--     , vb : List String
--     }

-- type B
--     = VA A

-- type alias Path =
--     { stepPath : String
--     , stepMaybe : Bool
--     , stepIndex : Int
--     }

-- testRule : DetectorEx (String -> Bool -> Int -> Path) B Msg 
-- testRule = andThen
--     (\path1 (VA bo) (VA bn) -> execute
--         ( batch 
--             [ goPath "va" .va 
--                 <| maybe (\i _ _ t -> i True 0)
--                     [ AddedEx <| \p -> always <| Msg <| p False 0
--                     , RemovedEx <| \p -> always <| Msg <| p False 0
--                     ]
--                 <| value 
--                     [ ChangedEx <| \p -> always <| always <| Msg p ]
--             , goPath "vb" .vb 
--                 <| mapPath (\i -> i False)
--                 <| inline
--                     [ ChangedEx <| \p -> always <| always <| Msg <| p -1 ]
--                 <| list
--                     (\i _ _ t -> i t) 
--                     (\i t -> i t) 
--                     [ AddedEx <| \p -> always <| Msg p 
--                     , RemovedEx <| \p -> always <| Msg p
--                     ]
--                 <| value
--                     [ ChangedEx <| \p -> always <| always <| Msg p ]
--             ]
--         )
--         path1 bo bn
--     )
