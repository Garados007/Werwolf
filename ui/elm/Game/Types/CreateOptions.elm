module Game.Types.CreateOptions exposing (..)

-- Create Options for a game
type alias CreateOptions =
    -- the chapter title
    { chapter : String
    -- box in the first layer with options
    , box : List Box
    }

-- A single Box with options
type alias Box =
    -- the key that refers later the value
    { key : String
    -- the visible title
    , title : String
    -- the content of this box
    , content : BoxContent
    }

-- defines the content of a box
type BoxContent
    -- the content is again a list of box
    = SubBox 
        SubBoxContent -- all child boxes
    -- the content is just a description
    -- this value is discarded in the creation
    | Desc 
        String -- the visible text
    -- a number can be defined
    | Num 
        Float -- minimum value
        Float -- maximum value
        Int -- digits
        Float -- default value
    -- a text can be defined
    | Text
        String -- default value
        String -- match pattern (regex)
    -- a boolean value can be defined
    | Check 
        Bool -- default value
    -- a single option from a list of options can be defined
    | OptList
        ( List -- list of options
            ( String --key
            , String --visible text
            ) 
        )

type SubBoxContent = SubBoxContent (List Box)