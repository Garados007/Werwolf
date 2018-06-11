module Game.UI.NewGame exposing (..)

import ModuleConfig as MC exposing (..)

import Html exposing (Html,div,text,node,input)
import Html.Attributes exposing (class,value,type_,attribute)
import Html.Events exposing (on,onClick,onInput)
import Task
import Json.Decode as Json
import Json.Encode as JE
import Dict exposing (Dict)
import Regex exposing (regex)
import Result

import Game.Configuration exposing (..)
import Game.Utils.Language exposing (..)
import Game.UI.Loading as Loading exposing (loading)
import Game.Types.CreateOptions exposing (..)
import Game.Types.Types exposing (..)
import Game.Types.Request exposing (NewGameConfig)

type NewGame = NewGame NewGameInfo

type alias NewGameInfo =
    { config: LangConfiguration
    , installedTypes : Maybe (List String)
    , currentType : Maybe String
    , group : Group
    , page : Pages
    , createOptions : Dict String CreateOptions
    , setting : Dict (List String) OValue
    , user : List User
    , targetUser : Maybe Int
    , rolesets : Dict String (List String)
    , selRoles : Dict String Int
    }

type NewGameMsg
    -- public msg
    = SetConfig LangConfiguration
    | SetInstalledTypes (List String)
    | SetCreateOptions (Dict String CreateOptions)
    | SetUser (List User)
    | SetRoleset (Dict String (List String))
    -- private msg
    | ChangeCurrentType String
    | ShowPage Pages
    | OnUpdate (List String) OValue
    | OnChangeTargetUser String
    | OnChangeLeader Int
    | OnChangeSelRole String String
    | OnCreateGame

type NewGameEvent
    = FetchLangSet String
    | ChangeLeader Int Int --group user
    | CreateGame NewGameConfig

type Pages = PCommon | PRoles | PSpecial

type OValue 
    = ONum Bool Float 
    | OText Bool String 
    | OCheck Bool 
    | OOpt Bool String

type PT = PTG (Dict String PT) | PTV JE.Value

type alias NewGameDef a = ModuleConfig NewGame NewGameMsg
    (LangConfiguration, Group) NewGameEvent a

getActiveRuleset : NewGame -> Maybe String
getActiveRuleset (NewGame info) = info.currentType

newGameModule : (NewGameEvent -> List a) -> (LangConfiguration, Group) ->
    (NewGameDef a, Cmd NewGameMsg, List a)
newGameModule = createModule
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }

init : (LangConfiguration, Group) -> (NewGame, Cmd NewGameMsg, List a)
init (config, group) =
    ( NewGame <| NewGameInfo
        config Nothing Nothing group PCommon Dict.empty 
        Dict.empty [] Nothing Dict.empty Dict.empty
    , Cmd.none
    , []
    )

makeInitOption : Box -> List String -> List (List String, OValue)
makeInitOption box key = case box.content of
    SubBox (SubBoxContent content) -> List.concat <|
        List.map (\b -> makeInitOption b <| key :< box.key) content
    Desc _ -> []
    Num min max digits default -> 
        [( key :< box.key
        , ONum ((min <= default) && (default <= max)) default 
        )]
    Text default pattern -> 
        [( key :< box.key
        , OText (Regex.contains (regex pattern) default) default 
        )]
    Check default -> [( key :< box.key, OCheck default )]
    OptList list ->
        [( key :< box.key
        , case list of
            [] -> OOpt False ""
            (key,text) :: os -> OOpt True key
        )]

view : NewGame -> Html NewGameMsg
view (NewGame info) = div [ class "w-newgame-box" ]
    [ div [ class "w-newgame-title" ]
        [ text <| getSingle info.config.lang [ "ui", "newgame" ] ]
    , div [ class "w-newgame-variants-box" ]
        [ div [ class "w-newgame-variants-title" ]
            [ text <| getSingle info.config.lang [ "ui", "ng-variants" ] ]
        , case info.installedTypes of
            Just it -> viewInstalledTypes it
            Nothing -> loading
        ]
    , div [ class "w-newgame-options-header" ] <|
        [ div [ class "w-newgame-options-header-item", onClick (ShowPage PCommon) ]
            [ text <| getSingle info.config.lang [ "ui", "ng-common" ] ]
        , div [ class "w-newgame-options-header-item", onClick (ShowPage PRoles) ]
            [ text <| getSingle info.config.lang [ "ui", "ng-roles" ] ]
        ]
        ++?
        [ Maybe.map (\ct ->
                div [ class "w-newgame-options-header-item", onClick (ShowPage PSpecial) ] <| 
                    List.singleton <| 
                        case Maybe.andThen (flip Dict.get info.createOptions) info.currentType of
                            Just co -> text <| getSingle info.config.lang 
                                [ "new-option", co.chapter ]
                            Nothing -> loading
            ) info.currentType
        ]
    , div [ class "w-newgame-options-page" ] <|
        ( case info.page of
            PCommon -> viewPageCommon
            PRoles -> viewPageRoles
            PSpecial -> viewPageSpecial
        ) info
    , if (info.currentType /= Nothing) &&
            ((List.sum <| Dict.values info.selRoles) == (List.length info.user)) &&
            (List.all
                (\(list,ov) -> case ov of
                    ONum er _ -> er
                    OText er _ -> er
                    OCheck _ -> True
                    OOpt er _ -> er
                ) <| Dict.toList info.setting
            )
        then div [ class "w-newgame-submit", onClick OnCreateGame ]
            [ text <| getSingle info.config.lang [ "ui", "create-newgame" ] ]
        else div [] []
    ]

viewInstalledTypes : List String -> Html NewGameMsg
viewInstalledTypes list = node "select"
    [ on "change" <|
        Json.map ChangeCurrentType Html.Events.targetValue
    ] <| List.map
    (\it -> node "option" 
        [ value it]
        [ text it]
    )
    list

viewPageCommon : NewGameInfo -> List (Html NewGameMsg)
viewPageCommon info = 
    [ div [ class "w-newgame-enterkey-header" ]
        [ text <| getSingle info.config.lang [ "ui", "enter-key" ]]
    , input
        [ class "w-newgame-enterkey-code" 
        , type_ "text"
        , attribute "readonly" "readonly"
        , value <| formatKey info.group.enterKey
        ] []
    , div [ class "w-newgame-cleader-header" ]
        [ text <| getSingle info.config.lang [ "ui", "change-leader" ] ]
    , node "select"
        [ class "w-newgame-cleader-select" 
        , on "change" <|
            Json.map OnChangeTargetUser Html.Events.targetValue
        ] <| List.map
        (\user ->
            node "option" [ value <| toString user.user ]
                [ text user.stats.name ]
        )
        info.user
    , case info.targetUser of
        Just tu -> div 
            [ class "w-newgame-cleader-submit" 
            , onClick <| OnChangeLeader tu
            ]
            [ text <| getSingle info.config.lang [ "ui", "on-change-leader" ] ]
        Nothing -> div [] []
    ]

viewPageRoles : NewGameInfo -> List (Html NewGameMsg)
viewPageRoles info =
    [ div [ class "w-newgame-roleset-header" ]
        [ text <| getSingle info.config.lang [ "ui", "rolesets" ] ]
    , div [ class "w-newgame-roleset-group" ] <|
        ( div [ class "w-newgame-roleset-single" ]
            [ divk <| text <| getSingle info.config.lang [ "ui", "role-leader" ]
            , divk <| text "1" 
            ]
        )
        ::
        ( List.map
            (\role -> div [ class "w-newgame-roleset-single" ]
                [ divk <| text <| getSingle info.config.lang [ "roles", role ]
                , divk <| input
                    [ type_ "number"
                    , attribute "min" "0"
                    , attribute "step" "1"
                    , attribute "max" <| toString <| List.length info.user
                    , value <| toString <| Maybe.withDefault 0 <|
                        Dict.get role info.selRoles
                    , onInput (OnChangeSelRole role)
                    ] []
                ]
            ) <| Maybe.withDefault [] <| 
            Maybe.andThen (flip Dict.get info.rolesets) <|
            info.currentType
        )
    , if (List.sum <| Dict.values info.selRoles) == (List.length info.user)
        then div [] []
        else div [ class "w-newgame-roleset-invalid" ]
            [ text <| getSingle info.config.lang ["ui", "role-invalid" ] ]
    ]

viewPageSpecial : NewGameInfo -> List (Html NewGameMsg)
viewPageSpecial info = case Maybe.andThen (flip Dict.get info.createOptions) info.currentType of
    Nothing -> [ loading ]
    Just option -> List.map
        (\box -> viewBox info.setting info.config.lang box [])
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
                List.map (\b -> viewBox setting lang b <| list :< box.key)
                content
            ]
    Desc desc -> div [ class "w-newgame-box-desc" ] <| List.singleton <|
        text <| getSingle lang [ "new-option", desc ]
    Num min max digits default -> 
        let onum = Dict.get (list :< box.key) setting
                |> Maybe.withDefault (ONum False default)
            (err,val) = case onum of
                ONum err val -> (not err,val)
                _ -> (False, default)
        in div 
            [ class <| (++) "w-newgame-box-num" <| if err then " error" else "" ]
            [ div [ class "w-newgame-box-otitle" ]
                [ text <| getSingle lang [ "new-option", box.title ] ]
            , divk <| input
                [ type_ "number"
                , value <| toString val
                , attribute "min" <| toString min
                , attribute "max" <| toString max
                , attribute "required" "required"
                , attribute "step" <| toString <| 10 ^ (-digits)
                , onInput
                    ( OnUpdate (list :< box.key) <<
                        (\value -> case String.toFloat value of
                            Ok v ->
                                if (min <= v) && (v <= max)
                                then ONum True v
                                else ONum False v
                            Err _ -> ONum False val
                        )
                    )
                ] []
            ] 
    Text default pattern -> 
        let otext = Dict.get (list :< box.key) setting
                |> Maybe.withDefault (OText (Regex.contains (regex pattern) default) default)
            (err,val) = case otext of
                OText err val -> (not err,val)
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
                    ( OnUpdate (list :< box.key) <<
                        (\value ->
                            if Regex.contains (regex pattern) value
                            then OText True value
                            else OText False value
                        )
                    )
                ] []
            ] 
    Check default ->
        let ocheck = Dict.get (list :< box.key) setting
                |> Maybe.withDefault (OCheck default)
            val = case ocheck of
                OCheck val -> val
                _ -> default
        in div 
            [ class "w-newgame-box-check" ]
            [ div [ class "w-newgame-box-otitle" ]
                [ text <| getSingle lang [ "new-option", box.title ] ]
            , divk <| input
                ([ type_ "checkbox"
                , value <| toString val
                , onClick
                    ( OnUpdate (list :< box.key) <| OCheck <| not val
                    )
                ] ++?
                [ if val then Just <| attribute "checked" "checked" else Nothing
                ]
                ) []
            ] 
    OptList olist -> 
        let oopt = Dict.get (list :< box.key) setting
                |> Maybe.withDefault (OOpt False "")
            (err,val) = case oopt of
                OOpt err val -> (not err,val)
                _ -> (False, "")
        in div 
            [ class <| (++) "w-newgame-box-opt" <| if err then " error" else "" ]
            [ div [ class "w-newgame-box-otitle" ]
                [ text <| getSingle lang [ "new-option", box.title ] ]
            , divk <| node "select" 
                [ on "change" <|
                    Json.map
                        (OnUpdate (list :< box.key) << OOpt True)
                        Html.Events.targetValue
                ] <| List.map
                (\(key,txt) ->
                    node "option"
                        ([ value key
                        ]
                        ++?
                        [ if key == val 
                            then Just <| attribute "selected" "selected"
                            else Nothing
                        ])
                        [ text <| getSingle lang ["new-option", txt] ]
                )
                olist
            ] 

update : NewGameDef a -> NewGameMsg -> NewGame -> (NewGame, Cmd NewGameMsg, List a)
update def msg (NewGame info) = case msg of
    SetConfig config -> (NewGame { info | config = config }, Cmd.none, [])
    SetInstalledTypes list -> 
        let nt = case info.currentType of
                    Just ct -> Just ct
                    Nothing -> case list of
                        [] -> Nothing
                        c::cs -> Just c
        in  ( NewGame 
                { info 
                | installedTypes = Just list 
                , currentType = nt
                }
            , Cmd.none
            , case nt of
                Just nct -> event def <| FetchLangSet nct
                Nothing -> []
            )
    SetCreateOptions createOptions ->
        (NewGame { info 
        | createOptions = createOptions 
        , setting = case info.currentType of
            Nothing -> Dict.empty
            Just ct -> case Dict.get ct createOptions of
                Nothing -> Dict.empty
                Just opt -> Dict.fromList <| List.concat <| 
                    List.map (\b -> makeInitOption b []) opt.box
        }, Cmd.none, [])
    SetUser user -> 
        (NewGame 
            { info 
            | user = user 
            , targetUser = if info.user == []
                then Maybe.map .user <| List.head user
                else info.targetUser
            }
        , Cmd.none
        , []
        )
    SetRoleset roleset ->
        (NewGame { info | rolesets = roleset }, Cmd.none, [])
    ChangeCurrentType nct ->
        ( NewGame { info | currentType = Just nct, selRoles = Dict.empty }
        , Cmd.none
        , event def <| FetchLangSet nct
        )
    ShowPage page ->
        (NewGame { info | page = page }, Cmd.none, [])
    OnUpdate keyl var ->
        (NewGame { info | setting = Dict.insert keyl var info.setting }, Cmd.none, [])
    OnChangeTargetUser userS ->
        (NewGame { info | targetUser = Result.toMaybe <| String.toInt userS }
        , Cmd.none
        , []
        )
    OnChangeLeader target ->
        (NewGame info, Cmd.none, event def <| ChangeLeader info.group.id target)
    OnChangeSelRole role text ->
        (NewGame 
            { info 
            | selRoles = case String.toInt text of
                Ok num -> if num < 0 then info.selRoles 
                    else Dict.insert role num info.selRoles
                Err _ -> info.selRoles
            }
        , Cmd.none
        , []
        )
    OnCreateGame ->
        (NewGame info, Cmd.none
        , event def <| CreateGame <| NewGameConfig
            info.group.id
            (prepairRoleList info.selRoles)
            (case info.currentType of
                Just ct -> ct
                Nothing -> Debug.crash "NewGame:update:OnCreateGame - require ruleset"
            )
            (prepairConfig info.setting)
        )

subscriptions : NewGame -> Sub NewGameMsg
subscriptions model = Sub.none

(++?) : List a -> List (Maybe a) -> List a
(++?) list = (++) list << List.filterMap identity

(:<) : List a -> a -> List a
(:<) list a = list ++ [a]

formatKey : String -> String
formatKey key =
    let ml : List Char -> List (List Char)
        ml = \list ->
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
        insertpt = \pt list val -> case list of
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
        translate = \pt -> case pt of
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