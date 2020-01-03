module Dashboard.Source exposing 
    ( Source (..)
    , build
    , textnl
    )

type Source 
    = SNone 
    | SText String 
    | SIndent Int 
    | SNewLine
    | SMulti (List Source)
    | SPushMarker
    | SRestoreMarker
    -- new independend source environment inside a source
    -- The embed region start with no indent and history
    | SEmbed Source 
    -- lazy evaluation
    | SLazy (() -> Source)
    -- sandbox the indent marker (insert after sandbox a line feed).
    -- the sandbox itself starts on the same indent level, but with
    -- empty indent history.
    | SSandbox Source

build : Int -> Source -> String 
build  indentSize source =
    let indent : String 
        indent = String.repeat indentSize " "
        nl : String 
        nl = if indentSize < 0 then "" else "\r\n"
        walker : Bool -> Int -> List Int -> List Source -> String
        walker hasCode curIndent history list = case list of 
            [] -> ""
            SNone::ls -> walker hasCode curIndent history ls 
            (SText v)::ls -> String.concat
                [ if hasCode
                    then ""
                    else String.repeat curIndent indent
                , v 
                , walker True curIndent history ls
                ]
            (SIndent v)::ls -> walker hasCode 
                (max 0 <| curIndent + v) 
                history ls 
            SNewLine::ls -> (++) nl <| walker False curIndent history ls 
            (SMulti v)::ls -> walker hasCode curIndent history <| v ++ ls 
            SPushMarker::ls -> walker hasCode curIndent (curIndent::history) ls 
            SRestoreMarker::ls -> case history of 
                [] -> walker hasCode 0 [] ls 
                v::vs -> walker hasCode v vs ls
            (SEmbed v)::ls -> 
                (build indentSize v)
                ++ (walker hasCode curIndent history ls)
            (SLazy v)::ls -> walker hasCode curIndent history <| (v ())::ls
            (SSandbox v)::ls -> 
                (walker hasCode curIndent [] [ v ])
                ++ nl
                ++ (walker False curIndent history ls)
    in walker False 0 [] [ source ]
    
-- output a text and after that a newline
textnl : String -> Source 
textnl text = SMulti [ SText text, SNewLine ]