module Game.Utils.UserLookup exposing
    ( UserLookup
    , empty
    , putChanges
    , getUser
    , getSingleUser
    , getGroupUser
    , getUserGroups
    )

import Game.Types.Types as Types exposing (..)
import Game.Types.Changes exposing (..)
import Dict exposing (Dict)
import Set exposing (Set)

type UserLookup = UserLookup UserLookupInfo

type alias UserLookupInfo = Dict Int UserEntry

type alias UserEntry =
    { stat : Maybe UserStat
    , groups : Set Int
    }

empty : UserLookup
empty = UserLookup Dict.empty

putChanges : List Changes -> UserLookup -> UserLookup
putChanges changes (UserLookup dict) =
    let insert : Changes -> UserLookupInfo -> UserLookupInfo
        insert = \change info -> case change of
            CUser user -> case Dict.get (Types.userId user.user) info of
                Just entry -> Dict.insert 
                    (Types.userId user.user)
                    { entry
                    | stat = Just user.stats
                    , groups = Set.insert (Types.groupId user.group) entry.groups
                    }
                    info
                Nothing -> Dict.insert
                    (Types.userId user.user)
                    { stat = Just user.stats
                    , groups = Set.singleton <| Types.groupId user.group
                    }
                    info
            CUserStat stat -> case Dict.get (Types.userId stat.userId) info of
                Just entry -> Dict.insert
                    (Types.userId stat.userId)
                    { entry | stat = Just stat }
                    info
                Nothing -> Dict.insert
                    (Types.userId stat.userId)
                    { stat = Just stat
                    , groups = Set.empty
                    }
                    info
            CLastOnline group online ->
                let users : Set Int
                    users = List.map 
                        (Tuple.first >> Types.userId) online 
                        |> Set.fromList
                    inserted : UserLookupInfo
                    inserted = Set.foldl
                        (\u d -> case Dict.get u d of
                            Just entry -> Dict.insert
                                u
                                { entry | groups = Set.insert 
                                    (Types.groupId group) 
                                    entry.groups 
                                }
                                d
                            Nothing -> Dict.insert
                                u
                                { stat = Nothing
                                , groups = Set.singleton <| Types.groupId group
                                }
                                d
                        )
                        info
                        users
                    removed : UserLookupInfo
                    removed = Dict.map
                        (\id entry ->
                            { entry
                            | groups = 
                                if Set.member id users
                                then entry.groups
                                else Set.remove (Types.groupId group) entry.groups
                            }
                        )
                        inserted
                in removed
            _ -> info
        insertAll : UserLookupInfo -> List Changes -> UserLookupInfo
        insertAll = List.foldl insert 
        clean : UserLookupInfo -> UserLookupInfo
        clean = Dict.filter
            (\_ entry -> not <| (entry.stat == Nothing) || (Set.isEmpty entry.groups) )
    in UserLookup <| clean <| insertAll dict changes

getUser : UserLookup -> List UserStat
getUser (UserLookup dict) = Dict.values dict |> List.filterMap .stat

getSingleUser : Int -> UserLookup -> Maybe UserStat
getSingleUser user (UserLookup dict) =
    Dict.get user dict
    |> Maybe.andThen .stat

getGroupUser : Int -> UserLookup -> List UserStat
getGroupUser group (UserLookup dict) = Dict.values dict 
    |> List.filter (.groups >> Set.member group)
    |> List.filterMap .stat

getUserGroups : Int -> UserLookup -> List Int
getUserGroups user (UserLookup dict) = Dict.get user dict
    |> Maybe.map (.groups >> Set.toList)
    |> Maybe.withDefault []