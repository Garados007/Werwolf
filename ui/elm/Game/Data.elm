module Game.Data exposing (..)

import Game.Types.Types as Types exposing (..)
import Game.Utils.Language exposing (..)
import Game.Utils.LangLoader exposing (LangInfo)
import Dict exposing (Dict)
import Time exposing (Posix, Zone)
import Game.Utils.UserLookup as UserLookup exposing (UserLookup)
import Game.Types.CreateOptions exposing (CreateOptions)
import Game.Types.Changes exposing (Changes(..))
import Config exposing (lang_backup)
import UnionDict exposing (UnionDict, SafeDict, unsafen, safen)
import Game.Configuration as Configuration exposing (Configuration)
import DataDiff.Path as Diff exposing (Path (..), DetectorPath)
import DataDiff.Ex exposing (ModActionEx)

type alias Data =
    { lang : LangData
    , time : TimeData
    , game : GameData
    , config : Configuration
    , error : ErrorLevel
    }

type ErrorLevel 
    = NoError
    | ErrAccountInvalid
    | ErrNetworkError
    | ErrMaintenance

type alias LangData =
    { global : LangGlobal
    , locals : SafeDict Int GroupId LangLocal
    , default : LangLocal
    , info : List LangInfo
    }

type alias TimeData =
    { now : Posix
    , zone : Zone
    }

type alias GameData =
    { ownId : Maybe UserId
    , groups : SafeDict Int GroupId GroupData 
    , users : UserLookup
    , rolesets : Dict String (List String)
    , installedTypes : Maybe (List String)
    , createOptions : Dict String CreateOptions
    , bans : List BanInfo
    , invalidGroups : Dict String Posix
    , bannedGroups : Dict String Posix
    }

type alias GroupData =  
    { group : Group
    , user : List User 
    , chats : SafeDict Int ChatId ChatData
    }

type alias ChatData =
    { chat : Chat 
    , entry : SafeDict Int ChatEntryId ChatEntry 
    , vote : SafeDict String VoteKey VoteData
    }

type alias VoteData =
    { voting : Voting
    , votes : SafeDict Int PlayerId Vote
    }

empty : Posix -> Zone -> Data 
empty now zone =
    { lang =
        { global = newGlobal lang_backup 
        , locals = UnionDict.include Dict.empty
        , default = createLocal (newGlobal lang_backup) Nothing
        , info = []
        }
    , time =
        { now = now
        , zone = zone
        }
    , game =
        { ownId = Nothing
        , groups = UnionDict.include Dict.empty
        , users = UserLookup.empty
        , rolesets = Dict.empty
        , installedTypes = Nothing
        , createOptions = Dict.empty
        , bans = []
        , invalidGroups = Dict.empty 
        , bannedGroups = Dict.empty
        }
    , config = Configuration.empty
    , error = NoError
    }

update : Changes -> Data -> Data
update changement data = 
    let model = data.game |> \game ->
            { data | game = 
                { game 
                | users = UserLookup.putChanges 
                    [ changement ] data.game.users 
                } 
            }
    in case changement of 
        CUserStat stat -> 
            { model 
            | game = data.game |> \game ->
                { game 
                | groups = unsafen GroupId Types.groupId game.groups
                    |> UnionDict.map
                        (\_ group ->
                            { group 
                            | user = List.map 
                                (\user ->
                                    if user.user == stat.userId 
                                    then { user | stats = stat }
                                    else user
                                )
                                group.user
                            }
                        )
                    |> safen
                }
            }
        CGroup ng ->
            { model 
            | game = model.game |> \game ->
                { game 
                | groups = unsafen GroupId Types.groupId game.groups
                    |> UnionDict.update ng.id 
                        (\mg -> Just <| case mg of
                            Just g -> { g | group = ng }
                            Nothing -> 
                                { group = ng 
                                , user = []
                                , chats = UnionDict.include Dict.empty
                                }
                        )
                    |> safen 
                }
            }
        CGame ng ->
            { model 
            | game = model.game |> \game ->
                { game 
                | groups = unsafen GroupId Types.groupId game.groups
                    |> UnionDict.update ng.mainGroupId
                        (Maybe.map <| \gd -> 
                            { gd
                            | group = gd.group |> \g -> 
                                { g 
                                | currentGame = Just ng 
                                }
                            }
                        )
                    |> safen 
                }
            }
        CUser nu ->
            { model 
            | game = model.game |> \game ->
                { game 
                | groups = unsafen GroupId Types.groupId game.groups
                    |> UnionDict.update nu.group
                        (Maybe.map <| \gd ->
                            { gd 
                            | user = 
                                if List.isEmpty
                                    <| List.filter 
                                        (.user >> (==) nu.user)
                                        gd.user
                                then gd.user ++ [ nu ]
                                else List.map
                                    (\u -> 
                                        if u.user == nu.user 
                                        then nu 
                                        else u
                                    )
                                    gd.user
                            }
                        )
                    |> safen
                }
            }
        CChat nc ->
            { model
            | game = model.game |> \game ->
                { game 
                | groups = unsafen GroupId Types.groupId game.groups
                    |> UnionDict.map
                        (\_ group -> 
                            if Maybe.map .id group.group.currentGame == Just nc.game
                            then 
                                { group
                                | chats = unsafen ChatId Types.chatId group.chats
                                    |> UnionDict.update nc.id 
                                        (\mc -> Just <| case mc of 
                                            Just c -> { c | chat = nc }
                                            Nothing ->
                                                { chat = nc
                                                , entry = UnionDict.include Dict.empty
                                                , vote = UnionDict.include Dict.empty
                                                }
                                        )
                                    |> safen
                                }
                            else group
                        )
                    |> safen
                }
            }
        CChatEntry ne ->
            { model 
            | game = model.game |> \game ->
                { game
                | groups = unsafen GroupId Types.groupId game.groups
                    |> UnionDict.map
                        (\_ group ->
                            { group 
                            | chats = unsafen ChatId Types.chatId group.chats 
                                |> UnionDict.update ne.chat
                                    (Maybe.map <| \chat -> 
                                        { chat
                                        | entry = unsafen ChatEntryId Types.chatEntryId chat.entry
                                            |> UnionDict.insert ne.id ne
                                            |> safen
                                        }
                                    )
                                |> safen
                            }
                        )
                    |> safen
                }
            }
        CVote nv ->
            { model 
            | game = model.game |> \game ->
                { game
                | groups = unsafen GroupId Types.groupId game.groups
                    |> UnionDict.map
                        (\_ group ->
                            { group 
                            | chats = unsafen ChatId Types.chatId group.chats 
                                |> UnionDict.update nv.setting
                                    (Maybe.map <| \chat -> 
                                        { chat
                                        | vote = unsafen VoteKey Types.voteKey chat.vote
                                            |> UnionDict.update nv.voteKey 
                                                (Maybe.map <| \vote ->
                                                    { vote
                                                    | votes = unsafen PlayerId Types.playerId vote.votes
                                                        |> UnionDict.insert nv.voter nv 
                                                        |> safen
                                                    }
                                                )
                                            |> safen
                                        }
                                    )
                                |> safen
                            }
                        )
                    |> safen
                }
            }
        CVoting nv ->
            { model 
            | game = model.game |> \game ->
                { game
                | groups = unsafen GroupId Types.groupId game.groups
                    |> UnionDict.map
                        (\_ group ->
                            { group 
                            | chats = unsafen ChatId Types.chatId group.chats 
                                |> UnionDict.update nv.chat
                                    (Maybe.map <| \chat -> 
                                        { chat
                                        | vote = unsafen VoteKey Types.voteKey chat.vote
                                            |> UnionDict.update nv.voteKey 
                                                (\mvote -> Just <| case mvote of
                                                    Just vote -> { vote | voting = nv }
                                                    Nothing ->
                                                        { voting = nv 
                                                        , votes = UnionDict.include Dict.empty
                                                        }
                                                )
                                            |> safen
                                        }
                                    )
                                |> safen
                            }
                        )
                    |> safen
                }
            }
        CLastOnline ng nl -> 
            { model 
            | game = model.game |> \game ->
                { game 
                | groups = unsafen GroupId Types.groupId game.groups 
                    |> UnionDict.update ng
                        (Maybe.map <| \group ->
                            { group 
                            | user = List.foldr
                                (\u r1 -> List.foldr
                                    (\(nu,nt) ru -> 
                                        (if ru.user == nu
                                        then
                                            { ru 
                                            | stats = u.stats |> \s ->
                                                { s | lastOnline = nt }
                                            }
                                        else ru
                                        )
                                    )
                                    u
                                    nl
                                    :: r1
                                )
                                []
                                group.user
                            }
                        )
                    |> safen
                }
            }
        CInstalledGameTypes nl ->
            { model 
            | game = model.game |> \game ->
                { game 
                | installedTypes = Just nl
                }
            }
        CCreateOptions nk no ->
            { model 
            | game = model.game |> \game ->
                { game 
                | createOptions = Dict.insert
                    nk no game.createOptions
                }
            }
        CRolesets nk nr ->
            { model 
            | game = model.game |> \game ->
                { game 
                | rolesets = Dict.insert nk nr game.rolesets
                }
            }
        CConfig nc ->
            { model
            | config = nc
                |> Maybe.map Configuration.decodeConfig
                |> Maybe.withDefault model.config
            }
        COwnId ni ->
            { model 
            | game = model.game |> \game ->
                { game 
                | ownId = Just ni
                }
            }
        CBanInfo nb ->
            { model
            | game = model.game |> \game ->
                { game 
                | bans =
                    if List.member nb game.bans
                    then game.bans
                    else nb :: game.bans
                }
            }
        CAccountInvalid ->
            { model
            | error = ErrAccountInvalid
            }
        CNetworkError ->
            { model 
            | error = ErrNetworkError
            }
        CMaintenance ->
            { model
            | error = ErrMaintenance
            }
        CErrInvalidGroupKey gk->
            { model
            | game = model.game |> \game ->
                { game 
                | invalidGroups = Dict.insert gk model.time.now 
                    game.invalidGroups
                }
            }
        CErrJoinBannedFromGroup gk ->
            { model 
            | game = model.game |> \game ->
                { game 
                | bannedGroups = Dict.insert gk model.time.now
                    game.bannedGroups
                }
            }
        CGroupLeaved ng ->
            { model
            | game = model.game |> \game ->
                { game 
                | groups = unsafen GroupId Types.groupId game.groups
                    |> UnionDict.remove ng
                    |> safen
                }
            }

pathTimeData : DetectorPath TimeData msg -> DetectorPath Data msg
pathTimeData = Diff.goPath (PathString "time") .time

pathLangData : DetectorPath LangData msg -> DetectorPath Data msg 
pathLangData = Diff.goPath (PathString "lang") .lang

pathGameData : DetectorPath GameData msg -> DetectorPath Data msg 
pathGameData = Diff.goPath (PathString "game") .game

pathGroupData 
    : List (ModActionEx (List Path) GroupData msg) 
    -> DetectorPath GroupData msg
    -> DetectorPath GameData msg 
pathGroupData = pathSafeDictInt "group" .groups

pathChatData 
    : List (ModActionEx (List Path) ChatData msg)
    -> DetectorPath ChatData msg 
    -> DetectorPath GroupData msg 
pathChatData = pathSafeDictInt "chat" .chats

pathVoteData
    : List (ModActionEx (List Path) VoteData msg)
    -> DetectorPath VoteData msg 
    -> DetectorPath ChatData msg 
pathVoteData = pathSafeDictString "vote" .vote

pathSafeDictInt 
    : String
    -> (b -> SafeDict Int k a)
    -> List (ModActionEx (List Path) a msg)
    -> DetectorPath a msg 
    -> DetectorPath b msg
pathSafeDictInt pathName cp mods = Diff.goPath (PathString pathName) cp
    << Diff.mapData UnionDict.extract
    << Diff.dict (\_ _ n -> PathInt n) PathInt mods

pathSafeDictString
    : String 
    -> (b -> SafeDict String k a)
    -> List (ModActionEx (List Path) a msg)
    -> DetectorPath a msg
    -> DetectorPath b msg
pathSafeDictString pathName cp mods = Diff.goPath (PathString pathName) cp
    << Diff.mapData UnionDict.extract
    << Diff.dict (\_ _ n -> PathString n) PathString mods