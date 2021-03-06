module Game.UI.NewGame exposing (..)

import Html exposing (Html,div,text,node,input)
import Html.Attributes exposing (class,value,type_,attribute,selected)
import Html.Events exposing (on,onClick,onInput)
import Task
import Json.Decode as Json
import Json.Encode as JE
import Dict exposing (Dict)
import Regex exposing (Regex)
import Result

import Game.Utils.Language exposing (..)
import Game.UI.Loading as Loading exposing (loading)
import Game.Types.CreateOptions exposing (..)
import Game.Types.Types as Types exposing (..)
import Game.Types.Request exposing (NewGameConfig)
import Game.Data as Data exposing (Data)
import DataDiff.Path as Diff exposing (DetectorPath, Path (..))
import DataDiff.Ex exposing (SingleActionEx (..), ModActionEx (..))
import UnionDict exposing (UnionDict)

regex : String -> Regex 
regex = Maybe.withDefault Regex.never << Regex.fromString

type NewGame = NewGame NewGameInfo

type alias NewGameInfo =
    { groupId : GroupId
    , currentType : Maybe String
    , page : Pages
    , setting : Dict (List String) OValue
    , targetUser : Maybe UserId
    , selRoles : Dict String Int
    }

type NewGameMsg
    -- public msg
    -- private msg
    = ChangeCurrentType Bool String
    | SetSetting (Dict (List String) OValue)
    | ShowPage Pages
    | OnUpdate (List String) OValue
    | OnChangeTargetUser Bool String
    | OnChangeLeader UserId
    | OnChangeSelRole String String
    | OnCreateGame
    | CallEvent (List NewGameEvent)
    | Multi (List NewGameMsg)

type NewGameEvent
    = FetchLangSet String
    | ChangeLeader GroupId UserId --group user
    | CreateGame NewGameConfig
    | ReqData (Data -> NewGameMsg)
    | ModData (Data -> Data)
    | RefreshLangList
    | FetchOptions String

type Pages = PCommon | PRoles | PSpecial

type OValue 
    = ONum Bool Float 
    | OText Bool String 
    | OCheck Bool 
    | OOpt Bool String

type PT 
    = PTG (Dict String PT) 
    | PTV JE.Value

getActiveRuleset : NewGame -> Maybe String
getActiveRuleset (NewGame info) = info.currentType

detector : NewGame -> DetectorPath Data NewGameMsg
detector (NewGame info) = Data.pathGameData
    <| Diff.batch
    [ Diff.mapData .installedTypes
        <| Diff.value
            [ ChangedEx <| \_ _ mt -> case mt of
                Just (c::cs) -> ChangeCurrentType False c
                _ -> CallEvent []
            ]
    , Diff.mapData .createOptions
        <| Diff.dict
            (\_ _ -> PathString)
            PathString
            [ AddedEx <| \path co ->
                let cot : String 
                    cot = List.reverse path 
                        |> List.head 
                        |> \pe -> case pe of 
                            Just (PathString s) -> s
                            _ -> ""
                in  if Just cot == info.currentType
                    then co.box 
                        |> List.concatMap (\b -> makeInitOption b [])
                        |> Dict.fromList
                        |> SetSetting
                    else CallEvent []
            ]
        <| Diff.value []
    , Diff.cond
            (\_ _ _ -> info.targetUser == Nothing)
        <| Data.pathGroupData []
        <| Diff.cond (\_ _ g -> g.group.id == info.groupId)
        <| Diff.mapData .user 
        <| Diff.list
            (\_ _ -> PathInt)
            [ AddedEx <| \_ u ->
                if info.targetUser == Nothing 
                then OnChangeTargetUser False
                    <| String.fromInt 
                    <| Types.userId u.user
                else CallEvent []
            ]
        <| Diff.value []
    ]

init : GroupId -> (NewGame, List NewGameEvent)
init groupId = 
    ( NewGame 
        { groupId = groupId
        , currentType = Nothing
        , page = PCommon
        , setting = Dict.empty
        , targetUser = Nothing
        , selRoles = Dict.empty
        }
    , List.singleton <| ReqData <| \data -> Multi 
        <| List.filterMap identity
            [ case data.game.installedTypes of 
                Just (t::ts) -> Just <| ChangeCurrentType False t
                _ -> Nothing
            , case data.game.installedTypes of 
                Just (t::ts) -> case Dict.get t data.game.createOptions of 
                    Nothing -> FetchOptions t
                        |> List.singleton
                        |> CallEvent 
                        |> Just
                    Just co -> co.box
                        |> List.concatMap (\b -> makeInitOption b [])
                        |> Dict.fromList
                        |> SetSetting
                        |> Just
                _ -> Nothing
            , data.game.groups 
                |> UnionDict.unsafen GroupId Types.groupId 
                |> UnionDict.get groupId 
                |> Maybe.map .user
                |> Maybe.andThen List.head
                |> Maybe.map
                    (.user 
                        >> Types.userId
                        >> String.fromInt
                        >> OnChangeTargetUser False
                    )
            ]
    )

makeInitOption : Box -> List String -> List (List String, OValue)
makeInitOption box key = case box.content of
    SubBox (SubBoxContent content) -> List.concat <|
        List.map (\b -> makeInitOption b <| addLast key box.key) content
    Desc _ -> []
    Num min max digits default -> 
        [( addLast key box.key
        , ONum ((min <= default) && (default <= max)) default 
        )]
    Text default pattern -> 
        [( addLast key box.key
        , OText (Regex.contains (regex pattern) default) default 
        )]
    Check default -> [( addLast key box.key, OCheck default )]
    OptList list ->
        [( addLast key box.key
        , case list of
            [] -> OOpt False ""
            (key2,text) :: os -> OOpt True key2
        )]

view : Data -> LangLocal -> NewGame -> Html NewGameMsg
view data lang (NewGame info) = div [ class "w-newgame-box" ]
    [ div [ class "w-newgame-title" ]
        [ text <| getSingle lang [ "ui", "newgame" ] ]
    , div [ class "w-newgame-variants-box" ]
        [ div [ class "w-newgame-variants-title" ]
            [ text <| getSingle lang [ "ui", "ng-variants" ] ]
        , case data.game.installedTypes of
            Just it -> viewInstalledTypes it
            Nothing -> loading
        ]
    , div [ class "w-newgame-options-header" ] <|
        addFiltered
        [ div [ class "w-newgame-options-header-item", onClick (ShowPage PCommon) ]
            [ text <| getSingle lang [ "ui", "ng-common" ] ]
        , div [ class "w-newgame-options-header-item", onClick (ShowPage PRoles) ]
            [ text <| getSingle lang [ "ui", "ng-roles" ] ]
        ]
        [ Maybe.map (\ct ->
                div [ class "w-newgame-options-header-item", onClick (ShowPage PSpecial) ] <| 
                    List.singleton <| 
                        case Maybe.andThen (\k -> Dict.get k data.game.createOptions) info.currentType of
                            Just co -> text <| getSingle lang 
                                [ "new-option", co.chapter ]
                            Nothing -> loading
            ) info.currentType
        ]
    , div [ class "w-newgame-options-page" ] <|
        ( case info.page of
            PCommon -> viewPageCommon
            PRoles -> viewPageRoles
            PSpecial -> viewPageSpecial
        ) data lang info 
    , if (info.currentType /= Nothing)
            &&  ( ((+) 1 <| List.sum <| Dict.values info.selRoles)
                    ==  ( data.game.groups
                            |> UnionDict.unsafen GroupId Types.groupId
                            |> UnionDict.get info.groupId 
                            |> Maybe.map .user 
                            |> Maybe.withDefault []
                            |> List.length
                        )
                )
            && (List.all
                (\(list,ov) -> case ov of
                    ONum er _ -> er
                    OText er _ -> er
                    OCheck _ -> True
                    OOpt er _ -> er
                ) <| Dict.toList info.setting
            )
        then div [ class "w-newgame-submit", onClick OnCreateGame ]
            [ text <| getSingle lang [ "ui", "create-newgame" ] ]
        else div [] []
    ]

viewInstalledTypes : List String -> Html NewGameMsg
viewInstalledTypes list = node "select"
    [ on "change" <|
        Json.map (ChangeCurrentType True) Html.Events.targetValue
    ] <| List.map
    (\it -> node "option" 
        [ value it]
        [ text it]
    )
    list

viewPageCommon : Data -> LangLocal -> NewGameInfo -> List (Html NewGameMsg)
viewPageCommon data lang info = 
    [ div [ class "w-newgame-enterkey-header" ]
        [ text <| getSingle lang [ "ui", "enter-key" ]]
    , input
        [ class "w-newgame-enterkey-code" 
        , type_ "text"
        , attribute "readonly" "readonly"
        , value 
            <| formatKey 
            <| Maybe.withDefault ""
            <| Maybe.map (.enterKey << .group)
            <| UnionDict.get info.groupId 
            <| UnionDict.unsafen GroupId Types.groupId
            <| data.game.groups
        ] []
    , div [ class "w-newgame-cleader-header" ]
        [ text <| getSingle lang [ "ui", "change-leader" ] ]
    , node "select"
        [ class "w-newgame-cleader-select" 
        , on "change" <|
            Json.map (OnChangeTargetUser True) Html.Events.targetValue
        ] 
        <| List.map
            (\user ->  node "option" 
                [ value <| String.fromInt <| Types.userId user.user ]
                [ text user.stats.name ]
            )
        <| Maybe.withDefault []
        <| Maybe.map .user 
        <| UnionDict.get info.groupId 
        <| UnionDict.unsafen GroupId Types.groupId
        <| data.game.groups
    , case info.targetUser of
        Just tu -> div 
            [ class "w-newgame-cleader-submit" 
            , onClick <| OnChangeLeader tu
            ]
            [ text <| getSingle lang [ "ui", "on-change-leader" ] ]
        Nothing -> div [] []
    ]

viewPageRoles : Data -> LangLocal -> NewGameInfo -> List (Html NewGameMsg)
viewPageRoles data lang info =
    [ div [ class "w-newgame-roleset-header" ]
        [ text <| getSingle lang [ "ui", "rolesets" ] ]
    , div [ class "w-newgame-roleset-group" ] <|
        ( div [ class "w-newgame-roleset-single" ]
            [ divk <| text <| getSingle lang [ "ui", "role-leader" ]
            , divk <| text "1" 
            ]
        )
        ::
        ( List.map
            (\role -> div [ class "w-newgame-roleset-single" ]
                [ divk <| text <| getSingle lang [ "roles", role ]
                , divk <| input
                    [ type_ "number"
                    , attribute "min" "0"
                    , attribute "step" "1"
                    , attribute "max" 
                        <| String.fromInt 
                        <| List.length 
                        <| Maybe.withDefault []
                        <| Maybe.map .user 
                        <| UnionDict.get info.groupId
                        <| UnionDict.unsafen GroupId Types.groupId
                        <| data.game.groups
                    , value 
                        <| String.fromInt 
                        <| Maybe.withDefault 0 
                        <| Dict.get role info.selRoles
                    , onInput (OnChangeSelRole role)
                    ] []
                ]
            ) <| Maybe.withDefault [] <| 
            Maybe.andThen (\k -> Dict.get k data.game.rolesets) <|
            info.currentType
        )
    , if (==) ((+) 1 <| List.sum <| Dict.values info.selRoles) 
            <| List.length 
            <| Maybe.withDefault []
            <| Maybe.map .user 
            <| UnionDict.get info.groupId
            <| UnionDict.unsafen GroupId Types.groupId
            <| data.game.groups
        then div [] []
        else div [ class "w-newgame-roleset-invalid" ]
            [ text <| getSingle lang ["ui", "role-invalid" ] ]
    ]

viewPageSpecial : Data -> LangLocal -> NewGameInfo -> List (Html NewGameMsg)
viewPageSpecial data lang info = case Maybe.andThen (\k -> Dict.get k data.game.createOptions) info.currentType of
    Nothing -> [ loading ]
    Just option -> List.map
        (\box -> viewBox info.setting lang box [])
        option.box

divk : Html msg -> Html msg
divk = div [] << List.singleton

viewBox : Dict (List String) OValue -> LangLocal -> Box -> List String -> Html NewGameMsg 
viewBox setting lang box list = case box.content of
    SubBox (SubBoxContent content) ->
        div [ class "w-newgame-box-subbox" ]
            [ div [ class "w-newgame-box-title" ] 
                [ text <| getSingle lang [ "new-option", box.title ] ]
            , div [ class "w-newgame-box-subbox-content" ] <|
                List.map (\b -> viewBox setting lang b <| addLast list box.key)
                content
            ]
    Desc desc -> div [ class "w-newgame-box-desc" ] <| List.singleton <|
        text <| getSingle lang [ "new-option", desc ]
    Num min max digits default -> 
        let onum = Dict.get (addLast list box.key) setting
                |> Maybe.withDefault (ONum False default)
            (err,val) = case onum of
                ONum err2 val2 -> (not err2,val2)
                _ -> (False, default)
        in div 
            [ class <| (++) "w-newgame-box-num" <| if err then " error" else "" ]
            [ div [ class "w-newgame-box-otitle" ]
                [ text <| getSingle lang [ "new-option", box.title ] ]
            , divk <| input
                [ type_ "number"
                , value <| String.fromFloat val
                , attribute "min" <| String.fromFloat min
                , attribute "max" <| String.fromFloat max
                , attribute "required" "required"
                , attribute "step" <| String.fromFloat <| 10.0 ^ (toFloat -digits)
                , onInput
                    ( OnUpdate (addLast list box.key) <<
                        (\value -> case String.toFloat value of
                            Just v ->
                                if (min <= v) && (v <= max)
                                then ONum True v
                                else ONum False v
                            Nothing -> ONum False val
                        )
                    )
                ] []
            ] 
    Text default pattern -> 
        let otext = Dict.get (addLast list box.key) setting
                |> Maybe.withDefault (OText (Regex.contains (regex pattern) default) default)
            (err,val) = case otext of
                OText err2 val2 -> (not err2, val2)
                _ -> (False, default)
        in div 
            [ class <| (++) "w-newgame-box-text" <| if err then " error" else "" ]
            [ div [ class "w-newgame-box-otitle" ]
                [ text <| getSingle lang [ "new-option", box.title ] ]
            , divk <| input
                [ type_ "text"
                , value val
                , attribute "pattern" pattern
                , attribute "required" "required"
                , onInput
                    ( OnUpdate (addLast list box.key) <<
                        (\value ->
                            if Regex.contains (regex pattern) value
                            then OText True value
                            else OText False value
                        )
                    )
                ] []
            ] 
    Check default ->
        let ocheck = Dict.get (addLast list box.key) setting
                |> Maybe.withDefault (OCheck default)
            val = case ocheck of
                OCheck val2 -> val2
                _ -> default
        in div 
            [ class "w-newgame-box-check" ]
            [ div [ class "w-newgame-box-otitle" ]
                [ text <| getSingle lang [ "new-option", box.title ] ]
            , divk <| input
                (addFiltered
                    [ type_ "checkbox"
                    , value <| if val then "true" else "false"
                    , onClick
                        ( OnUpdate (addLast list box.key) <| OCheck <| not val
                        )
                    ]
                    [ if val then Just <| attribute "checked" "checked" else Nothing
                    ]
                ) []
            ] 
    OptList olist -> 
        let oopt = Dict.get (addLast list box.key) setting
                |> Maybe.withDefault (OOpt False "")
            (err,val) = case oopt of
                OOpt err2 val2 -> (not err2, val2)
                _ -> (False, "")
        in div 
            [ class <| (++) "w-newgame-box-opt" <| if err then " error" else "" ]
            [ div [ class "w-newgame-box-otitle" ]
                [ text <| getSingle lang [ "new-option", box.title ] ]
            , divk <| node "select" 
                [ on "change" <|
                    Json.map
                        (OnUpdate (addLast list box.key) << OOpt True)
                        Html.Events.targetValue
                ] <| List.map
                (\(key,txt) ->
                    node "option"
                        [ value key
                        , selected <| key == val
                        ]
                        [ text <| getSingle lang ["new-option", txt] ]
                )
                olist
            ] 

update : NewGameMsg -> NewGame -> (NewGame, Cmd NewGameMsg, List NewGameEvent)
update msg (NewGame info) = case msg of
    ChangeCurrentType override nct ->
        ( NewGame 
            { info 
            | currentType = 
                if override
                then Just nct
                else info.currentType 
                    |> Maybe.withDefault nct 
                    |> Just
            , selRoles = Dict.empty 
            }
        , Cmd.none
        ,   [ FetchLangSet nct 
            , ModData <| \data -> 
                { data 
                | game = data.game |> \game ->
                    { game
                    | groups = game.groups
                        |> UnionDict.unsafen GroupId Types.groupId
                        |> UnionDict.update info.groupId
                            ( Maybe.map <| \group ->
                                { group 
                                | newGameLang = Just nct
                                }
                            )
                        |> UnionDict.safen
                    }
                }
            , FetchOptions nct
            , RefreshLangList
            ]
        )
    SetSetting set ->
        ( NewGame { info | setting = set }, Cmd.none, [])
    ShowPage page ->
        (NewGame { info | page = page }, Cmd.none, [])
    OnUpdate keyl var ->
        (NewGame { info | setting = Dict.insert keyl var info.setting }, Cmd.none, [])
    OnChangeTargetUser override userS ->
        (NewGame 
            { info 
            | targetUser = 
                if override
                then String.toInt userS  |> Maybe.map UserId
                else case info.targetUser of 
                    Just tu -> info.targetUser
                    Nothing -> String.toInt userS |> Maybe.map UserId
            }
        , Cmd.none
        , []
        )
    OnChangeLeader target ->
        ( NewGame info
        , Cmd.none
        , [ ChangeLeader  info.groupId target ]
        )
    OnChangeSelRole role text ->
        (NewGame 
            { info 
            | selRoles = case String.toInt text of
                Just num -> if num < 0 then info.selRoles 
                    else Dict.insert role num info.selRoles
                Nothing -> info.selRoles
            }
        , Cmd.none
        , []
        )
    OnCreateGame ->
        (NewGame info, Cmd.none
        , List.singleton <| CreateGame <| NewGameConfig
            info.groupId
            (prepairRoleList info.selRoles)
            (case info.currentType of
                Just ct -> ct
                Nothing -> Debug.todo "NewGame:update:OnCreateGame - require ruleset"
            )
            (prepairConfig info.setting)
        )
    CallEvent event -> (NewGame info, Cmd.none, event)
    Multi msgs -> List.foldr
            (\m (nm, cmds, events) ->
                let (rm, rcmd, re) = update m nm 
                in (rm, rcmd :: cmds, re ++ events)
            )
            (NewGame info, [], [])
            msgs
        |> \(nm, cmds, events) -> (nm, Cmd.batch cmds, events)

-- former operator ++? (custom operators are removed in elm 0.19)
addFiltered : List a -> List (Maybe a) -> List a
addFiltered list = (++) list << List.filterMap identity

-- former operator :< (custom operators are removed in elm 0.19)
addLast : List a -> a -> List a 
addLast list a = list ++ [a]

formatKey : String -> String
formatKey key =
    let ml : List Char -> List (List Char)
        ml list =
            if list == []
            then []
            else (List.take 4 list) :: (ml <| List.drop 4 list)
    in String.fromList <| List.concat <|
        List.intersperse [' '] <| ml <| String.toList key

prepairRoleList : Dict String Int -> Dict String Int
prepairRoleList =
    Dict.filter (\k v -> v > 0)

prepairConfig : Dict (List String) OValue -> JE.Value
prepairConfig =
    let convOvalue : OValue -> JE.Value
        convOvalue = \ov -> case ov of
            ONum _ v -> JE.float v
            OText _ v -> JE.string v
            OCheck v -> JE.bool v
            OOpt _ v -> JE.string v
        insertpt : PT -> List String -> JE.Value -> PT
        insertpt pt list val = case list of
            [] -> PTV val
            l :: ls -> case pt of
                PTV _ -> PTG <| Dict.insert l 
                    (insertpt (PTG Dict.empty) ls val) Dict.empty
                PTG group -> PTG <| Dict.insert l
                    ( insertpt 
                        ( PTG <| Maybe.withDefault Dict.empty <| 
                            case Dict.get l group of
                                Just (PTG dict) -> Just dict
                                Just (PTV _) -> Nothing
                                Nothing -> Nothing
                        )
                        ls
                        val
                    )
                    group
        translate : PT -> JE.Value
        translate pt = case pt of
            PTG dict -> JE.object <| 
                List.map (\(k,v) -> (k, translate v)) <| 
                Dict.toList dict
            PTV val -> val
    in translate << List.foldr
        (\(list, val) pt ->
            insertpt pt list <| convOvalue val
        )
        (PTG Dict.empty) <<
        Dict.toList