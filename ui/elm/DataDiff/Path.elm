module DataDiff.Path exposing 
    ( Path (..)
    , DetectorPath 
    , ChangePath
    , ActionPath
    , directPath
    , value
    , list
    , dict
    , maybe
    , mapData
    , mapMsg
    , batch
    , execute
    , andThen
    , inline
    , goPath
    )

-- elm/core
import Dict exposing (Dict)

-- local
import DataDiff.Ex as DDEx exposing (..)

type Path
    = PathInt Int 
    | PathFloat Float 
    | PathString String
    | PathMaybeJust

type alias DetectorPath data msg = DetectorEx (List Path) data msg 

type alias ChangePath data token =
    data -> data -> token -> Path

type alias ActionPath token = 
    token -> Path 

directPath : (token -> Path) -> ChangePath data token 
directPath func = \_ _ t -> func t

exChange : ChangePath data token -> PathModify (List Path) (List Path) data token 
exChange cp = \i o n t -> i ++ [ cp o n t ]

exAction : ActionPath token -> ActionModify (List Path) (List Path) token 
exAction ap = \i t -> i ++ [ ap t ]

value : List (SingleActionEx (List Path) data msg) -> DetectorPath data msg 
value = DDEx.value

list : ChangePath data Int 
    -> List (ModActionEx (List Path) data msg) 
    -> DetectorPath data msg 
    -> DetectorPath (List data) msg 
list cp = DDEx.list (exChange cp) (exAction PathInt)

dict : ChangePath data comparable 
    -> ActionPath comparable 
    -> List (ModActionEx (List Path) data msg)
    -> DetectorPath data msg 
    -> DetectorPath (Dict comparable data) msg 
dict cp ap = DDEx.dict (exChange cp) (exAction ap) 

maybe : List (ModActionEx (List Path) data msg) 
    -> DetectorPath data msg 
    -> DetectorPath (Maybe data) msg 
maybe = DDEx.maybe (exChange (\_ _ _ -> PathMaybeJust))

mapData : (b -> a) -> DetectorPath a msg -> DetectorPath b msg 
mapData = DDEx.mapData

mapMsg : (a -> b) -> DetectorPath data a -> DetectorPath data b 
mapMsg = DDEx.mapMsg

batch : List (DetectorPath data msg) -> DetectorPath data msg 
batch = DDEx.batch

execute : DetectorPath data msg -> List Path -> data -> data -> List msg 
execute = DDEx.execute

andThen : (List Path -> data -> data -> List msg) -> DetectorPath data msg 
andThen = DDEx.andThen 

inline : List (SingleActionEx (List Path) data msg)
    -> DetectorPath data msg 
    -> DetectorPath data msg 
inline = DDEx.inline

goPath : Path
    -> (data1 -> data2) 
    -> DetectorPath data2 msg 
    -> DetectorPath data1 msg 
goPath token func detector = DDEx.mapPath (\p -> p ++ [token])
    <| mapData func detector
