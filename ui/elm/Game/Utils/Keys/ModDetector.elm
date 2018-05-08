module Game.Utils.Keys.ModDetector exposing
    ( ModDetector
    , setDown
    , setUp
    , isShift
    , isCtrl
    , isAlt
    , isPressed
    , newModDetector
    )

import Game.Utils.Keys exposing (keyShift,keyCtrl,keyAlt)
import Set exposing (Set,insert,remove,member,empty)
type ModDetector =
    InternalModDetector IntMod

type alias IntMod =
    { shift : Bool
    , ctrl : Bool
    , alt : Bool
    , pressed : Set Int
    }

setDown : ModDetector -> Int -> ModDetector
setDown (InternalModDetector mod) key =
    let
        shift = mod.shift || (key == keyShift)
        ctrl = mod.ctrl || (key == keyCtrl)
        alt = mod.alt || (key == keyAlt)
        pressed = insert key mod.pressed
    in
        InternalModDetector 
            (IntMod shift ctrl alt pressed)

setUp : ModDetector -> Int -> ModDetector
setUp (InternalModDetector mod) key =
    let
        shift = mod.shift && (key /= keyShift)
        ctrl = mod.ctrl && (key /= keyCtrl)
        alt = mod.alt && (key /= keyAlt)
        pressed = remove key mod.pressed
    in InternalModDetector 
        (IntMod shift ctrl alt pressed)

isShift : ModDetector -> Bool
isShift (InternalModDetector mod) =
    mod.shift

isCtrl : ModDetector -> Bool
isCtrl (InternalModDetector mod) =
    mod.ctrl

isAlt : ModDetector -> Bool
isAlt (InternalModDetector mod) =
    mod.alt

isPressed : ModDetector -> Int -> Bool
isPressed (InternalModDetector mod) key =
    member key mod.pressed

newModDetector : ModDetector
newModDetector =
    InternalModDetector 
        (IntMod False False False empty)