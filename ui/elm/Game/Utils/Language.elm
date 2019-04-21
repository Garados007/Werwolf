module Game.Utils.Language exposing
    ( LangVars
    , LangGlobal
    , LangLocal
    , newGlobal
    , createLocal
    , addMainLang
    , addSpecialLang
    , getSingle
    , getSpecial
    , getChatName
    , getVotingName
    , getGameset
    , hasGameset
    , allGamesets
    , hasLanguage
    , allLanguages
    , getCurLang
    , getCurLangLocal
    , decodeSpecial
    , updateCurrentLang
    , updateUser
    , updateChats
    )

import Json.Decode as Json exposing 
    (Decoder,oneOf,string,dict,lazy,list,field,succeed,int,index)
import Json.Decode.Pipeline exposing (required,optional)
import Dict exposing (Dict)
import Set exposing (Set)
import Game.Types.Types as Types exposing (..)

type LanguageLibTile
    = Text String
    | Group (Dict String LanguageLibTile)
    | Special (List LanguageLibSpecial)

type LanguageLibSpecial
    = Raw String
    | UserName String
    | ChatRoomName String
    | VoteKeyName String

type LangVars = LangVars (() -> LanguageVars)

type alias LanguageVars = 
    { key : List String
    , user : Dict String Int
    , chat : Dict String Int
    , voteKey : Dict String (Int, String)
    }

type alias LangLibConfig =
    { user: List User
    , chats: Dict Int Chat
    }

type LangLocal = LangLocal (() -> LanguageLocal)

type alias LanguageLocal =
    { config : LangLibConfig
    , main : Maybe LanguageLibTile
    , game : Maybe LanguageLibTile
    , curLang : String
    , gameset : Maybe String
    }

type LangGlobal = LangGlobal (() -> LanguageGlobal)

type alias LanguageGlobal =
    { curLang : String
    , texts : Dict String LanguageLibTile
    , gameTexts : Dict String (Dict String LanguageLibTile)
    }

addMainLang : LangGlobal -> String -> String -> LangGlobal
addMainLang (LangGlobal info) lang code =
    let pi = info ()
    in LangGlobal <| \() ->
        case Json.decodeString decodeLib code of
            Ok lib -> { pi | texts = Dict.insert lang lib pi.texts }
            Err _ -> pi

addSpecialLang : LangGlobal -> String -> String -> String -> LangGlobal
addSpecialLang (LangGlobal info) lang game code =
    let pi = info ()
    in LangGlobal <| \() ->
        case Json.decodeString decodeLib code of
            Ok lib ->
                let d = Maybe.withDefault Dict.empty <|
                        Dict.get lang pi.gameTexts
                    ud = Dict.insert game lib d
                in { pi | gameTexts = Dict.insert lang ud pi.gameTexts }
            Err _ -> pi

newGlobal : String -> LangGlobal
newGlobal lang = LangGlobal <| \() -> 
    LanguageGlobal lang Dict.empty Dict.empty

updateCurrentLang : LangGlobal -> String -> LangGlobal
updateCurrentLang (LangGlobal info) newLang =
    let pi = info ()
    in LangGlobal <| \() -> { pi | curLang = newLang }

createLocal : LangGlobal -> Maybe String -> LangLocal
createLocal (LangGlobal info) game =
    let pi = info ()
    in  LangLocal <| \() -> LanguageLocal
        (LangLibConfig [] Dict.empty)
        (Dict.get pi.curLang pi.texts)
        (Maybe.andThen
            (\g -> Maybe.andThen
                (Dict.get g)
                (Dict.get pi.curLang pi.gameTexts)
            )
            game
        )
        pi.curLang
        game

getGameset : LangLocal -> Maybe String
getGameset (LangLocal info) = (info ()).gameset

hasGameset : LangGlobal -> String -> String -> Bool
hasGameset (LangGlobal info) lang ruleset =
    let l = info ()
    in Dict.get lang l.gameTexts
        |> Maybe.map (Dict.member ruleset)
        |> Maybe.withDefault False

allGamesets : LangGlobal -> Set String
allGamesets (LangGlobal info) =
    let l = info ()
    in Dict.values l.gameTexts
        |> List.map Dict.keys
        |> List.concat
        |> Set.fromList

{-| searches for any entry -}
hasLanguage : LangGlobal -> String -> Bool
hasLanguage (LangGlobal info) lang =
    let l = info ()
    in  (Dict.member lang l.texts) ||
        (Dict.member lang l.gameTexts) 

allLanguages : LangGlobal -> Set String
allLanguages (LangGlobal info) =
    let l = info ()
    in Dict.keys l.texts
        |> (++) (Dict.keys l.gameTexts)
        |> Set.fromList

getCurLang : LangGlobal -> String
getCurLang (LangGlobal info) = (info ()).curLang

getCurLangLocal : LangLocal -> String
getCurLangLocal (LangLocal info) = (info ()).curLang

updateUser : LangLocal -> List User -> LangLocal
updateUser (LangLocal info) list =
    let pi = info ()
        c = pi.config
        uc = { c | user = list }
    in LangLocal <| \() -> { pi | config = uc }

updateChats : LangLocal -> Dict Int Chat -> LangLocal
updateChats (LangLocal info) dict =
    let pi = info ()
        c = pi.config
        uc = { c | chats = dict }
    in LangLocal <| \() -> { pi | config = uc }

getSingle : LangLocal -> List String -> String
getSingle (LangLocal info) list =
    let
        mfetch : Maybe LanguageLibTile -> Maybe String
        mfetch = \tile -> case tile of
            Nothing -> Nothing
            Just t -> fetchSingle (info ()).config t list
    in case mfetch (info ()).main of
        Just text -> text
        Nothing -> case mfetch (info ()).game of
            Just text -> text
            Nothing -> 
                "[" ++ (String.concat <| List.intersperse "->" list) ++ "]"

getSpecial : LangLocal -> LangVars -> String
getSpecial (LangLocal info) (LangVars vars_) =
    let
        vars = vars_ ()
        mfetch : Maybe LanguageLibTile -> Maybe String
        mfetch = \tile -> case tile of
            Nothing -> Nothing
            Just t -> fetchSpecial (info ()).config t vars
    in case mfetch (info ()).main of
        Just text -> text
        Nothing -> case mfetch (info ()).game of
            Just text -> text
            Nothing -> 
                "[" ++ (String.concat <| List.intersperse "->" vars.key) ++ "]"

decodeSpecial : String -> Maybe LangVars
decodeSpecial text =
    if String.startsWith "#json" text
    then
        case Json.decodeString decodeVars (String.dropLeft 5 text) of
            Ok vars -> Just <| LangVars <| \() -> vars
            Err _ -> Nothing
    else Nothing

decodeLib : Decoder LanguageLibTile
decodeLib = oneOf
    [ Json.map Text string
    , Json.map Group <| dict <| lazy <| \() -> decodeLib
    , Json.map Special <| list <| oneOf
        [ Json.map Raw <| field "t" string
        , Json.map UserName <| field "u" string
        , Json.map ChatRoomName <| field "r" string
        , Json.map VoteKeyName <| field "v" string
        ]
    ]

decodeVars : Decoder LanguageVars
decodeVars = oneOf
    [ succeed LanguageVars
        |> required "key" (list string)
        |> optional "user" (dict int) Dict.empty
        |> optional "chat" (dict int) Dict.empty
        |> optional "votes" 
            (dict 
                (Json.map2 (\a b -> (a,b))
                    (index 0 int)
                    (index 1 string)
                )
            ) Dict.empty
    , Json.map (\k -> LanguageVars k Dict.empty Dict.empty Dict.empty)
        <| list string
    ]

fetchSingle : LangLibConfig -> LanguageLibTile -> List String -> Maybe String
fetchSingle config tile list =
    case list of
        [] -> case tile of
            Text text -> Just text
            _ -> Nothing
        k :: ks -> case tile of
            Group dict -> case Dict.get k dict of
                Just sub -> fetchSingle config sub ks
                Nothing -> Nothing
            _ -> Nothing

fetchSpecial : LangLibConfig -> LanguageLibTile -> LanguageVars -> Maybe String
fetchSpecial config tile vars =
    let special : LanguageLibTile -> List String -> 
            Maybe (List LanguageLibSpecial)
        special sub list =
            case list of
                [] -> case sub of
                    Text text -> Just [ Raw text ]
                    Special sp -> Just sp
                    _ -> Nothing
                k :: ks -> case sub of
                    Group dict -> case Dict.get k dict of
                        Just s -> special s ks
                        Nothing -> Nothing
                    _ -> Nothing
        findUser : List User -> Int -> Maybe User
        findUser list id = case list of
            [] -> Nothing
            l :: ls ->
                if Types.userId l.user == id
                then Just l
                else findUser ls id
    in case special tile vars.key of
        Nothing -> Nothing
        Just spec -> Just <| String.concat <| List.map
            (\sp -> case sp of
                Raw text ->  text
                UserName key -> case Dict.get key vars.user of
                    Nothing -> "{" ++ key ++ "}"
                    Just id -> case findUser config.user id of
                        Nothing -> "User #" ++ (String.fromInt id)
                        Just u -> u.stats.name
                ChatRoomName key -> case Dict.get key vars.chat of
                    Nothing -> "{" ++ key ++ "}"
                    Just id -> case Dict.get id config.chats of
                        Nothing -> "Chat #" ++ (String.fromInt id)
                        Just c -> getChatNameInt config tile c.chatRoom
                VoteKeyName key -> case Dict.get key vars.voteKey of
                    Nothing -> "{" ++ key ++ "}"
                    Just (cid, vk) -> case Dict.get cid config.chats of
                        Nothing -> "Voting #" ++ vk ++ "@" ++ (String.fromInt cid)
                        Just c -> getVotingNameInt config tile c.chatRoom vk
            )
            spec

getChatName : LangLocal -> String -> String
getChatName lang key = getSingle lang [ "chat-names", key ]

getVotingName : LangLocal -> String -> String -> String
getVotingName lang ckey vkey = getSingle lang [ "voting-names", ckey, vkey ]

getChatNameInt : LangLibConfig -> LanguageLibTile -> String -> String
getChatNameInt config lib key =
    case fetchSingle config lib ["chat-names", key] of
        Just t -> t
        Nothing -> "[" ++ key ++ "]"

getVotingNameInt : LangLibConfig -> LanguageLibTile -> String -> String -> String
getVotingNameInt config lib ckey vkey =
    case fetchSingle config lib ["voting-names", ckey, vkey] of
        Just t -> t
        Nothing -> "[" ++ ckey ++ "->" ++ vkey ++ "]"
