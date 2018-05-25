<?php

include_once __DIR__ . '/ApiBase.php';

class GetApi extends ApiBase {
    public function hello(){
        return "hello world";
    }

    public function getUserStats(){
        if (($result = $this->getData(array(
            'user' => 'int'
        ))) !== true)
            return $this->wrapError($result);
        $this->inclDb('UserStats');
        $user = UserStats::create($this->formated['user']);
        if ($user === null)
            return $this->wrapError($this->errorId('user id not found'));
        return $this->wrapResult($this->setUserName($user));
    }

    public function getOwnUserStat() {
        if (($result = $this->getAccount()) !== true)
            return $this->wrapError($result);
        $user = UserStats::create($this->account['id']);
        if ($user === null)
            $user = UserStats::createNewUserStats($this->account['id']);
        return $this->wrapResult($this->setUserName($user));
    }

    public function getGroup() {
        if (($result = $this->getAccount()) !== true)
            return $this->wrapError($result);
        if (($result = $this->getData(array(
            'group' => 'int'
        ))) !== true)
            return $this->wrapError($result);
        $this->inclPerm();
        if (($result = Permission::canGetGroupData(
            $this->account['id'],
            $this->formated['group']
        )) !== true) return $this->wrapError($result);

        $this->inclDb('Group');
        $group = Group::create($this->formated['group']);
        if ($group === null)
            return $this->wrapError($this->errorId('group id not found'));
        return $this->wrapResult($group);
    }

    public function getUser() {
        if (($result = $this->getAccount()) !== true)
            return $this->wrapError($result);
        if (($result = $this->getData(array(
            'group' => 'int',
            'user' => 'int'
        ))) !== true)
            return $this->wrapError($result);
        $this->inclPerm();
        if (($result = Permission::canGetGroupData(
            $this->account['id'],
            $this->formated['group']
        )) !== true) return $this->wrapError($result);

        $this->inclDb('User');
        foreach (User::loadAllUserByGroup($this->formated['group']) as $user)
            if ($user->user == $this->formated['user']) {
                $user = $this->filterUser($this->formated['group'], $user);
                return $this->wrapResult($this->setUserName($user));
            }
        return $this->wrapError($this->errorId('user not found'));
    }

    public function getUserFromGroup() {
        if (($result = $this->getAccount()) !== true)
            return $this->wrapError($result);
        if (($result = $this->getData(array(
            'group' => 'int'
        ))) !== true)
            return $this->wrapError($result);
        $this->inclPerm();
        if (($result = Permission::canGetGroupData(
            $this->account['id'],
            $this->formated['group']
        )) !== true) return $this->wrapError($result);

        $this->inclDb('User');
        $user = User::loadAllUserByGroup($this->formated['group']);
        $user = $this->filterUser($this->formated['group'], $user);
        return $this->wrapResult($this->setUserName($user));
    }

    public function getMyGroupUser() {
        if (($result = $this->getAccount()) !== true)
            return $this->wrapError($result);
        if (($result = $this->getData(array(
        ))) !== true)
            return $this->wrapError($result);

        $this->inclDb('User');
        $user = User::loadAllGroupsByUser($this->account['id']);
        $result = array();
        foreach (User::loadAllGroupsByUser($this->account['id']) as $user)
            if (($res = $this->filterUser($user->group, $user)) !== null)
                $result[] = $res;
        return $this->wrapResult($this->setUserName($result));
    }

    public function getConfig() {
        if (($result = $this->getAccount()) !== true)
            return $this->wrapError($result);
        if (($result = $this->getData(array(
        ))) !== true)
            return $this->wrapError($result);

        $this->inclDb('UserConfig');
        $conf = UserConfig::create($this->account['id']);
            return $this->wrapResult($conf);
    }

    public function getChatRoom() {
        if (($result = $this->getAccount()) !== true)
            return $this->wrapError($result);
        if (($result = $this->getData(array(
            'chat' => 'int'
        ))) !== true)
            return $this->wrapError($result);
        $this->inclPerm();
        if (($result = Permission::canGetChatData(
            $this->account['id'],
            $this->formated['chat']
        )) !== true) return $this->wrapError($result);

        $this->inclDb('ChatRoom');
        $chat = ChatRoom::create($this->formated['chat']);
        $chat = $this->filterChatRooms($chat->game, $chat);
        if ($chat === null)
            return $this->wrapError($this->errorId('chat id not found'));
        return $this->wrapResult($chat);
    }

    public function getChatRooms() {
        if (($result = $this->getAccount()) !== true)
            return $this->wrapError($result);
        if (($result = $this->getData(array(
            'game' => 'int'
        ))) !== true)
            return $this->wrapError($result);
        $this->inclPerm();

        $this->inclDb('ChatRoom');
        $result = array();
        foreach (ChatRoom::getAllChatRoomIds($this->formated['game']) as $id) {
            $chat = ChatRoom::create($id);
            if ((Permission::canGetChatData(
                $this->account['id'],
                $chat->id
            )) === true) $result[] = $chat;
        }
        $result = $this->filterChatRooms($this->formated['game'], $result);
        return $this->wrapResult($result);
    }

    public function getChatEntrys() {
        if (($result = $this->getAccount()) !== true)
            return $this->wrapError($result);
        if (($result = $this->getData(array(
            'chat' => 'int'
        ))) !== true)
            return $this->wrapError($result);
        $this->inclPerm();
        if (($result = Permission::canGetChatData(
            $this->account['id'],
            $this->formated['chat']
        )) !== true) return $this->wrapError($result);

        $this->inclDb('ChatEntry');
        $result = ChatEntry::loadAllEntrys(
            $this->formated['chat'], 
            0
        );
        return $this->wrapResult($result);
    }

    public function getVotes() {
        if (($result = $this->getAccount()) !== true)
            return $this->wrapError($result);
        if (($result = $this->getData(array(
            'chat' => 'int',
            'voteKey' => [ 'regex', '/^.{1,5}$/']
        ))) !== true)
            return $this->wrapError($result);
        $this->inclPerm();
        if (($result = Permission::canGetChatData(
            $this->account['id'],
            $this->formated['chat']
        )) !== true) return $this->wrapError($result);

        $this->inclDb('VoteEntry', 'VoteSetting');
        $voting = VoteSetting::create(
            $this->formated['chat'],
            $this->formated['voteKey']
        );
        if ($voting === null)
            return $this->wrapError($this->errorId('voting not found'));
        $result = VoteEntry::getVotesBySetting($voting);
        return $this->wrapResult($result);
    }

    private function filterUser($group, $user) {
        $this->inclDb('VisibleRole','User');
        if (is_array($user)) {
            $result = array();
            foreach ($user as $u) {
                $r = $this->filterUser($group, $u);
                if ($r === null) continue;
                $result[] = $r;
            }
            return $result;
        }
        else {
            foreach (User::loadAllUserByGroup($group) as $u)
                if ($u->user == $this->account['id']) {
                    $cuser = $u;
                    break;
                }
            if (!isset($cuser)) return null;
            if ($user instanceof User) {
                if ($user->player === null) return $user;
                $json = $user->exportJson();
                $target = $user->player;
            }
            else if (is_array($user)) {
                $json = $user;
                if ($user['player'] === null) return $user;
                $target = Player::create($user['player']['id']);
            }
            else return null;
            if ($cuser->player === null) return null;
            $roles = VisibleRole::filterRoles($cuser->player, $target);
            $json['player']['roles'] = $roles;
            return $json;
        }
    }

    private function filterChatRooms($game, $rooms) {
        $this->inclDb('GameGroup','Player');
        if (is_array($rooms)) {
            $result = array();
            foreach ($rooms as $c) {
                $r = $this->filterChatRooms($game, $c);
                if ($r === null) continue;
                $result[] = $r;
            }
            return $result;
        }
        else {
            $game = GameGroup::create($game);
            foreach (User::loadAllUserByGroup($game->mainGroupId) as $u)
                if ($u->user == $this->account['id']) {
                    $cuser = $u;
                    break;
                }
            if (!isset($cuser) || $cuser->player === null) return null;
            if (is_array($rooms))
                $rooms = ChatRoom::create($rooms['id']);
            else if (is_int($rooms))
                $rooms = ChatRoom::create($rooms);
            $json = $rooms->exportJson();
            if (!$cuser->player->canRead($rooms))
                return null;
            $json['permission'] = array(
                'enable' => true,
                'write' => $cuser->player->canWrite($rooms),
                'visible' => $cuser->player->isVisible($rooms),
                'player' => $this->getVisibleUser($game->mainGroupId, $rooms)
            );
            return $json;
        }
    }

    private function getVisibleUser($group, ChatRoom $room) {
        $result = array();
        foreach (User::loadAllUserByGroup($group) as $user)
            if ($user->player !== null && $user->player->isVisible($room))
                $result[] = $user->player->id;
        return $result;
    }

    private static $userNameBuffer = array();

    private function setUserName($userJson) {
        $this->inclDb('JsonExport');
        if ($userJson instanceof JsonExport) {
            $json = $userJson->exportJson();
            return $this->setUserName($json);
        }
        elseif (isset($userJson['stats'])) {
            $userJson['stats'] = $this->setUserName($userJson['stats']);
            return $userJson;
        }
        elseif (!isset($userJson['userId'])) {
            $result = array();
            foreach ($userJson as $user)
                $result[] = $this->setUserName($user);
            return $result;
        }
        else {
            $id = $userJson['userId'];
            if (!isset(self::$userNameBuffer[$id])) {
                $this->getAccount();
                self::$userNameBuffer[$id] =
                    AccountManager::GetAccountName($id);
            }
            $userJson['name'] = self::$userNameBuffer[$id];
            return $userJson;
        }
    }
}