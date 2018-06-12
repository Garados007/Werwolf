<?php

include_once __DIR__ . '/../../db/ChatRoom/ChatRoom.php';
include_once __DIR__ . '/../../db/GameGroup/GameGroup.php';
include_once __DIR__ . '/../../db/Group/Group.php';
include_once __DIR__ . '/../../db/Role/Role.php';
include_once __DIR__ . '/../../db/User/User.php';
include_once __DIR__ . '/../../db/VoteSetting/VoteSetting.php';
include_once __DIR__ . '/../Role/RoleHandler.php';

class Permission {
    //region error handler

    private static function error($key, $info) {
        return array(
            "key" => $key,
            "info" => $info
        );
    }

    private static function errorId($info) {
        return self::error("wrongId", $info);
    }

    private static function errorStatus($info) {
        return self::error("wrongStatus", $info);
    }

    //endregion

    //region join group

    public static function canJoinGroup($userid, $key) {
        $id = Group::getIdFromKey($key);
        if ($id === null)
            return self::errorId("group key not found in db");
        foreach (User::loadAllUserByGroup($id) as $user)
            if ($user->user == $userid)
                return self::errorStatus("user is already in group");
        return true;
    }

    //endregion

    //region leave group

    public static function canLeaveGroup($userid, $group) {
        $user = User::loadSingle($userid, $group);
        if ($user === null)
            return self::errorId("user is not a member of this group");
        if ($user->player !== null)
            return self::errorStatus("game is running");
        $g = Group::create($group);
        if ($g->leader != $userid) return true;
        $users = User::loadAllUserByGroup($group);
        if (count($users) > 1)
            return self::errorStatus("user is leader of non empty group");
        return true;
    }

    //endregion

    //region start new game

    public static function canStartNewGame($userid, $groupId) {
        $group = Group::create($groupId);
        if ($group === null)
            return self::errorId("group id not found");
        if ($group->leader != $userid)
            return self::errorStatus("user is not the group leader");
        if ($group->currentGame !== null && $group->currentGame->finished === null)
            return self::errorStatus("unfinished game exists");
        return true;
    }

    public static function validateRoleList($groupId, $mode, array $roleList) {
        $group = Group::create($groupId);
        if ($group === null) return self::errorId("group id not found");
        $user = count(User::loadAllUserByGroup($groupId));
        $count = 0;
        $roles = RoleHandler::loadConfig($mode);
        if ($roles === false) return self::errorId("mode does not exist");
        foreach ($roleList as $role => $c) {
            if (!in_array($role, $roles->roles))
                return self::errorId("Role ${role} does not exist in mode");
            $count += $c;
        }
        if ($count + 1 > $user)
            return self::errorId("they are not enough player in this group");
        if ($count + 1 < $user)
            return self::errorId("not enough roles are defined");
        return true;
    }

    public static function validateGameOptions($mode, $options) {
        if (!is_file(__DIR__ . "/../Role/${mode}/varinfo.json"))
            return false;
        $opts = json_decode(file_get_contents(__DIR__ . "/../Role/${mode}/varinfo.json"));
        return self::validateOptionGroup($options, $opts->box);
    }

    private static function validateOptionGroup($option, $box) {
        if (is_array($box)) {
            $keys = array_keys($option);
            foreach ($box as $b) {
                if ($b->type == "desc") continue;
                if (!in_array($b->key, $keys))
                    return false;
                if (($key = array_search($b->key, $keys)) !== false) {
                    unset($keys[$key]);
                }
                $value;
                switch ($b->type) {
                    case "box": $value = $b->box; break;
                    default: $value = $b; break;
                }
                if (!self::validateOptionGroup($option[$b->key], $value))
                    return false;
            }
            return true;
        }
        else {
            switch ($box->type) {
                case "num":
                    $value = intval($option);
                    if (property_exists($box, "min"))
                        if ($value < $box->min)
                            return false;
                    if (property_exists($box, "max"))
                        if ($value > $box->max)
                            return false;
                    if (property_exists($box, "digits")) {
                        $val = $value * pow(10, $box->digits);
                        if (abs(floor($val) - $val) > 1e3)
                            return false;
                    }
                    break;
                case "text":
                    $value = strval($option);
                    if (property_exists($box, "regex"))
                        if (!preg_match($box->regex, $option))
                            return false;
                    break;
                case "list":
                    $value = strval($option);
                    if (!in_array($value, $box->options))
                        return false;
            }
            return true;
        }
    }

    //endregion

    //region change group leader

    public static function canChangeGroupLeader($userid, $groupId, $newLeaderId) {
        $group = Group::create($groupId);
        if ($group === null)
            return self::errorId("group id not found");
        if ($group->leader != $userid)
            return self::errorStatus("user is not the group leader");
        if ($userid == $newLeaderId)
            return self::errorId("user is already leader");
        foreach (User::loadAllUserByGroup($groupId) as $user)
            if ($user->user == $newLeaderId)
                return true;
        return self::errorId("new leader is not member of this group");
    }

    //endregion

    //region change phase

    public static function canChangePhase($userid, $gameid) {
        $game = GameGroup::create($gameid);
        if ($game === null)
            return self::errorId("game id not found");
        $handler = new RoleHandler($game);
        $roles = $handler->createAllControler();
        foreach (User::loadAllUserByGroup($game->mainGroupId) as $user)
            if ($user->user == $userid) {
                if ($user->player === null)
                    return self::errorStatus("user is not an active player");
                foreach ($user->player->roles as $role)
                    if ($roles[$role->roleKey]->canStartNewRound)
                        return true;
                return self::errorStatus("user has no rights to change phase");
            }
        return self::errorId("user is not in this game");
    }

    //endregion

    //region post chat

    public static function canPostChat($userid, $chatid) {
        $chat = ChatRoom::create($chatid);
        if ($chat === null)
            return self::errorId("chat id not found");
        $roles = array();
        foreach ($chat->permission as $permission)
            if ($permission->write)
                $roles[] = $permission->roleKey;
        if (count($roles) == 0)
            return self::errorStatus("nobody can write in this chat");
        $game = GameGroup::create($chat->game);
        foreach (User::loadAllUserByGroup($game->mainGroupId) as $user)
            if ($user->user == $userid) {
                if ($user->player === null)
                    return self::errorStatus("user is not an active player");
                foreach ($user->player->roles as $role)
                    if (in_array($role->roleKey, $roles))
                        return true;
                return self::errorStatus("no write permission granted");
            }
        return self::errorStatus("user is not a member of group");
    }

    //endregion

    //region voting

    public static function canStartVoting($userid, $chatId, $voteKey) {
        $voting = VoteSetting::create($chatId, $voteKey);
        if ($voting === null)
            return self::errorId("voting not found");
        if ($voting->voteEnd !== null)
            return self::errorStatus("voting is finished");
        if ($voting->voteStart !== null)
            return self::errorStatus("voting is already started");
        $chat = ChatRoom::create($chatId);
        $game = GameGroup::create($chat->game);
        $handler = new RoleHandler($game);
        $roles = $handler->createAllControler();
        foreach (User::loadAllUserByGroup($game->mainGroupId) as $user)
            if ($user->user == $userid) {
                if ($user->player === null)
                    return self::errorStatus("user is not an active player");
                foreach ($user->player->roles as $role)
                    if ($roles[$role->roleKey]->canStartVotings)
                        return true;
                return self::errorStatus("user has no rights to start voting");
            }
        return self::errorStatus("user is not a member of group");
    }

    public static function canFinishVoting($userid, $chatId, $voteKey) {
        $voting = VoteSetting::create($chatId, $voteKey);
        if ($voting === null)
            return self::errorId("voting not found");
        if ($voting->voteEnd !== null)
            return self::errorStatus("voting is finished");
        if ($voting->voteStart === null)
            return self::errorStatus("voting is never started");
        $chat = ChatRoom::create($chatId);
        $game = GameGroup::create($chat->game);
        $handler = new RoleHandler($game);
        $roles = $handler->createAllControler();
        foreach (User::loadAllUserByGroup($game->mainGroupId) as $user)
            if ($user->user == $userid) {
                if ($user->player === null)
                    return self::errorStatus("user is not an active player");
                foreach ($user->player->roles as $role)
                    if ($roles[$role->roleKey]->canStopVotings)
                        return true;
                return self::errorStatus("user has no rights to finish voting");
            }
        return self::errorStatus("user is not a member of group");
    }

    public static function canVote($playerid, $chatId, $voteKey, $targetId) {
        $voting = VoteSetting::create($chatId, $voteKey);
        if ($voting === null)
            return self::errorId("voting not found");
        if ($voting->voteStart === null)
            return self::errorStatus("voting is not started");
        if ($voting->voteEnd !== null)
            return self::errorStatus("voting is already finished");
        if (!in_array($playerid, $voting->enabledUser))
            return self::errorStatus("user is not allowed to vote");
        if (!in_array($targetId, $voting->targetUser))
            return self::errorStatus("target is not selectable");
        return true;
    }

    //endregion

    //region get any data

    public static function canGetGroupData($userid, $groupId) {
        $group = Group::create($groupId);
        if ($group === null)
            return self::errorId("group not found");
        foreach (User::loadAllUserByGroup($groupId) as $user)
            if ($user->user == $userid)
                return true;
        return self::errorStatus("user is not in the group");
    }

    public static function canGetChatData($userid, $chatid) {
        $chat = ChatRoom::create($chatid);
        if ($chat === null)
            return self::errorId("chat not found");
        $game = GameGroup::create($chat->game);
        foreach (User::loadAllUserByGroup($game->mainGroupId) as $user)
            if ($user->user == $userid) {
                if ($user->player !== null) {
                    $roles = array();
                    foreach ($chat->permission as $permission)
                        if ($permission->enable)
                            $roles[] = $permission->roleKey;
                    foreach ($user->player->roles as $role)
                        if (in_array($role->roleKey, $roles))
                            return true;
                    return self::errorStatus("user has no permissions to read this chat");
                }
                else {
                    $config = RoleHandler::loadConfig($game->ruleset);
                    if (in_array($chat->chatRoom, $config->chats_exceptions))
                        return true;
                    return self::errorStatus("guests has no permissions to read this chat");
                }
            }
        return self::errorStatus("user is not in the group");
    }

    //endregion
}