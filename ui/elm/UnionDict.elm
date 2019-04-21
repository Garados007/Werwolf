module UnionDict exposing 
    ( UnionDict 
    , empty, insert, update, remove
    , isEmpty, member, get, size
    , keys, values, toList, fromList
    , map, foldl, foldr, filter, partition
    , union, intersect, diff, merge

    , SafeDict
    , safen, unsafen, extract, include
    )

import Dict exposing (Dict)

-- with this type you can use union types as dictionary keys.
-- this collection is unable to serialize because it contains the comparing functions
type alias UnionDict comparable key value =
    { dict : Dict comparable value
    , conv1 : comparable -> key
    , conv2 : key -> comparable
    }

-- this dictionary is a slim wrapper to UnionDict but does not contains any
-- functions. Therefore you can serialize it without any problems. But you
-- cannot use any utility functions with it unless you unsafen it.
type SafeDict comparable key value =
    SafeDict (Dict comparable value)

-- makes the UnionDict safe to serialize but no functions can be performed 
-- on it because all comparisons are removed
safen : UnionDict comparable key value -> SafeDict comparable key value 
safen dict = SafeDict dict.dict 

-- makes the SafeDict ready to work and attach the comparion functions to it.
-- After this step this collections cannot be serialized!
unsafen : (comparable -> key) -> (key -> comparable) -> SafeDict comparable key value -> UnionDict comparable key value
unsafen conv1 conv2 (SafeDict dict) = UnionDict dict conv1 conv2 

extract : SafeDict comparable key value -> Dict comparable value
extract (SafeDict dict) = dict 

include : Dict comparable value -> SafeDict comparable key value 
include = SafeDict

empty : (comparable -> key) -> (key -> comparable) -> UnionDict comparable key value
empty conv1 conv2 =
    { dict = Dict.empty
    , conv1 = conv1
    , conv2 = conv2
    }

get : key -> UnionDict comparable key value -> Maybe value
get key dict = Dict.get (dict.conv2 key) dict.dict

member : key -> UnionDict comparable key value -> Bool 
member key dict = Dict.member (dict.conv2 key) dict.dict 

size : UnionDict comparable key value -> Int 
size = .dict >> Dict.size

isEmpty : UnionDict comparable key value -> Bool 
isEmpty = .dict >> Dict.isEmpty

insert : key -> value -> UnionDict comparable key value -> UnionDict comparable key value
insert key value dict =
    { dict | dict = Dict.insert (dict.conv2 key) value dict.dict }

remove : key -> UnionDict comparable key value -> UnionDict comparable key value
remove key dict =
    { dict | dict = Dict.remove (dict.conv2 key) dict.dict }

update : key -> (Maybe value -> Maybe value) -> UnionDict comparable key value -> UnionDict comparable key value
update key alter dict =
    { dict | dict = Dict.update (dict.conv2 key) alter dict.dict }

union : UnionDict comparable key value -> UnionDict comparable key value -> UnionDict comparable key value
union t1 t2 = foldl insert t2 t1

intersect : UnionDict comparable key value -> UnionDict comparable key value -> UnionDict comparable key value
intersect t1 t2 = filter (\k _ -> member k t2) t1

diff : UnionDict comparable key value -> UnionDict comparable key value -> UnionDict comparable key value
diff t1 t2 = foldl (\k v t -> remove k t) t1 t2

merge
    : (key -> a -> result -> result)
    -> (key -> a -> b -> result -> result)
    -> (key -> b -> result -> result)
    -> UnionDict comparable key a
    -> UnionDict comparable key b 
    -> result
    -> result
merge left both right ldict rdict init = Dict.merge 
    (\k a r -> left (ldict.conv1 k) a r) 
    (\k a b r -> both (ldict.conv1 k) a b r)
    (\k b r -> right (rdict.conv1 k) b r)
    ldict.dict 
    rdict.dict
    init 

map : (key -> a -> b) -> UnionDict comparable key a -> UnionDict comparable key b 
map func dict =
    { dict = Dict.map
        (\k a -> func (dict.conv1 k) a)
        dict.dict 
    , conv1 = dict.conv1 
    , conv2 = dict.conv2
    }

foldl : (key -> value -> b -> b) -> b -> UnionDict comparable key value -> b 
foldl func acc dict = Dict.foldl 
    (\k v b -> func (dict.conv1 k) v b)
    acc
    dict.dict 

foldr : (key -> value -> b -> b) -> b -> UnionDict comparable key value -> b 
foldr func acc dict = Dict.foldr
    (\k v b -> func (dict.conv1 k) v b)
    acc
    dict.dict 

filter : (key -> value -> Bool) -> UnionDict comparable key value -> UnionDict comparable key value
filter isGood dict =
    { dict | dict = Dict.filter (\k v -> isGood (dict.conv1 k) v) dict.dict }

partition : (key -> value -> Bool) -> UnionDict comparable key value -> (UnionDict comparable key value, UnionDict comparable key value)
partition isGood dict =
    let (d1, d2) = Dict.partition
            (\k v -> isGood (dict.conv1 k) v)
            dict.dict
    in  ( { dict | dict = d1 }
        , { dict | dict = d2 }
        )

keys : UnionDict comparable key value -> List key 
keys dict = Dict.keys dict.dict 
    |> List.map dict.conv1

values : UnionDict comparable key value -> List value 
values dict = Dict.values dict.dict 

toList : UnionDict comparable key value -> List (key, value)
toList dict = Dict.toList dict.dict 
    |> List.map (Tuple.mapFirst dict.conv1)

fromList : (comparable -> key) -> (key -> comparable) -> List (key, value) -> UnionDict comparable key value
fromList conv1 conv2 assocs =
    List.foldl (\(k,v) dict -> insert k v dict) (empty conv1 conv2) assocs

