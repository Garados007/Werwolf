module DataDiff exposing 
    ( Detector
    , ModAction (..)
    , SingleAction (..)
    , andThen
    , batch
    , dict
    , execute
    , inline
    , list
    , map
    , maybe
    , value
    , wrap
    )

-- elm/core
import Dict exposing (Dict)

type ModAction a msg 
    = Added (a -> msg)
    | Removed (a -> msg)

type SingleAction a msg
    = Changed (a -> a -> msg)

type Detector a msg 
    = Detector (a -> a -> List msg)

value : List (SingleAction a msg) -> Detector a msg 
value mlist = Detector <| \old new ->
    if old /= new 
    then List.concatMap
        (\m -> case m of 
            Changed f -> [ f old new ]
        )
        mlist
    else []

list : List (ModAction a msg) -> Detector a msg -> Detector (List a) msg 
list mlist (Detector det) = Detector <|
    \old new ->
        let comp : List a -> List a -> List msg 
            comp l1 l2 = case l1 of 
                [] -> List.concatMap 
                    (\m -> case m of 
                        Added f -> List.map f l2
                        _ -> []
                    )
                    mlist
                l1e :: l1l -> case l2 of 
                    [] -> List.concatMap 
                        (\m -> case m of 
                            Removed f -> List.map f l1
                            _ -> []
                        )
                        mlist
                    l2e :: l2l -> det l1e l2e
        in comp old new
        
dict : List (ModAction (comparable,value) msg) -> Detector value msg -> Detector (Dict comparable value) msg
dict mlist (Detector det) = Detector <|
    \old new -> Dict.merge
        (\k o r -> (++) r 
            <| List.filterMap
                (\m -> case m of 
                    Removed f -> Just <| f (k, o)
                    _ -> Nothing
                )
                mlist
        )
        (\k o n r -> (++) r 
            <| det o n
        )
        (\k n r -> (++) r 
            <| List.filterMap
                (\m -> case m of 
                    Added f -> Just <| f (k, n)
                    _ -> Nothing
                )
                mlist
        )
        old
        new
        []

maybe : List (ModAction a msg) -> Detector a msg -> Detector (Maybe a) msg
maybe mlist (Detector det) = Detector <|
    \old new -> case old of 
        Just o -> case new of 
            Just n -> det o n
            Nothing -> List.filterMap 
                (\m -> case m of 
                    Removed f -> Just <| f o
                    _ -> Nothing
                )
                mlist 
        Nothing -> case new of 
            Just n -> List.filterMap 
                (\m -> case m of 
                    Added f -> Just <| f n 
                    _ -> Nothing
                )
                mlist
            Nothing -> []

map : (b -> a) -> Detector a msg -> Detector b msg
map func (Detector det) = Detector <|
    \old new ->
        if old == new 
        then []
        else det (func old) (func new)

wrap : (msg1 -> msg2) -> Detector a msg1 -> Detector a msg2
wrap func (Detector det) = Detector <|
    \old new -> List.map func <| det old new

batch : List (Detector a msg) -> Detector a msg 
batch detectors = Detector <|
    \old new -> List.concatMap
        (\(Detector d) -> d old new)
        detectors

execute : Detector a msg -> a -> a -> List msg 
execute (Detector det) = det

andThen : (a -> a -> List msg) -> Detector a msg 
andThen = Detector

inline : List (SingleAction a msg) -> Detector a msg -> Detector a msg 
inline mlist detector = batch
    [ value mlist
    , detector
    ]

-- tests

-- type Msg 
--     = Msg

-- type alias A =
--     { va : Maybe Int
--     , vb : List String
--     }

-- type B
--     = VA A

-- testRule : Detector B Msg
-- testRule = andThen
--     (\(VA bo) (VA bn) -> execute
--         ( batch 
--             [ map .va
--                 <| maybe
--                     [ Added <| always Msg 
--                     , Removed <| always Msg 
--                     ]
--                 <| value 
--                     [ Changed <| always << always Msg ]
--             , map .vb 
--                 <| inline   
--                     [ Changed <| always << always Msg ]
--                 <| list
--                     [ Added <| always Msg 
--                     , Removed <| always Msg 
--                     ]
--                 <| value
--                     [ Changed <| always << always Msg ]
--             ]
--         )
--         bo bn
--     )

