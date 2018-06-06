<?php

include_once __DIR__ . '/ApiBase.php';

class ControlApi extends ApiBase {
    public function createGroup() {
        if (($result = $this->getAccount()) !== true)
            return $this->wrapError($result);
        if (($result = $this->getData(array(
            'name' => 'string'
        ))) !== true)
            return $this->wrapError($result);
        $this->inclDb('Group', 'UserStats', 'User');
        $user = UserStats::create($this->account['id']);
        if ($user === null) {
            $user = UserStats::createNewUserStats($this->account['id']);
        }
        $group = Group::createGroup(
            $this->formated['name'],
            $this->account['id']
        );
        User::createUser($group->id, $user->userId);
        return $this->wrapResult($group);
    }

    public function joinGroup() {
        if (($result = $this->getAccount()) !== true)
            return $this->wrapError($result);
        if (($result = $this->getData(array(
            'key' => [ 'regex', '/^[0-9A-HJ-NP-UW-Za-hj-np-uw-z]{12}$/' ]
        ))) !== true)
            return $this->wrapError($result);
        $this->inclPerm();
        if (($result = Permission::canJoinGroup(
            $this->account['id'],
            $this->formated['key']
        )) !== true) return $this->wrapError($result);

        $this->inclDb('Group', 'UserStats', 'User');
        $id = Group::getIdFromKey($this->formated['key']);
        $group = Group::create($id);
        $user = UserStats::create($this->account['id']);
        if ($user === null) {
            $user = UserStats::createNewUserStats($this->account['id']);
        }
        User::createUser($group->id, $user->userId);
        return $this->wrapResult($group);
    }

    public function changeLeader() {
        if (($result = $this->getAccount()) !== true)
            return $this->wrapError($result);
        if (($result = $this->getData(array(
            'group' => 'int',
            'leader' => 'int'
        ))) !== true)
            return $this->wrapError($result);
        $this->inclPerm();
        if (($result = Permission::canChangeGroupLeader(
            $this->account['id'],
            $this->formated['group'],
            $this->formated['leader']
        )) !== true) return $this->wrapError($result);
        
        $this->inclDb('Group');
        $group = Group::create($this->formated['group']);
        $group->setLeader($this->formated['leader']);
        return $this->wrapResult($group);
    }

    public function startNewGame() {
        if (($result = $this->getAccount()) !== true)
            return $this->wrapError($result);
        if (($result = $this->getData(array(
            'group' => 'int',
            'roles' => 'json',
            'ruleset' => [ 'regex', '/[a-zA-Z0-9_\-]+/' ],
            'config' => 'json'
        ))) !== true)
            return $this->wrapError($result);
        $this->inclPerm();
        if (($result = Permission::canStartNewGame(
            $this->account['id'],
            $this->formated['group']
        )) !== true) return $this->wrapError($result);
        if (($result = Permission::validateRoleList(
            $this->formated['group'],
            $this->formated['ruleset'],
            $this->formated['roles']
        )) !== true) return $this->wrapError($result);
        if (!Permission::validateGameOptions(
            $this->formated['ruleset'],
            $this->formated['config']
        )) return $this->wrapError($this->errorFormat('config is not valid'));

        $this->inclDb('Group', 'GameGroup');
        $this->inclRolH();
        $group = Group::create($this->formated['group']);
        $game = GameGroup::createNew(
            $this->formated['group'],
            '',
            $this->formated['ruleset'],
            $this->formated['config']
        );
        $group->setCurrentGame(null);
        $group->setCurrentGame($game);
        $roleH = new RoleHandler($game);
        $roleH->startGame(
            $this->formated['roles']
        );
        return $this->wrapResult($game);
    }

    public function nextPhase() {
        if (($result = $this->getAccount()) !== true)
            return $this->wrapError($result);
        if (($result = $this->getData(array(
            'game' => 'int'
        ))) !== true)
            return $this->wrapError($result);
        $this->inclPerm();
        if (($result = Permission::canChangePhase(
            $this->account['id'],
            $this->formated['game']
        )) !== true) return $this->wrapError($result);
        
        $this->inclDb('GameGroup');
        $this->inclRolH();
        $game = GameGroup::create($this->formated['game']);
        $roleH = new RoleHandler($game);
        $roleH->nextRound();
        return $this->wrapResult($game);
    }

    public function postChat() {
        if (($result = $this->getAccount()) !== true)
            return $this->wrapError($result);
        if (($result = $this->getData(array(
            'chat' => 'int',
            'text' => [ 'regex', '/^.{1,1024}$/']
        ))) !== true)
            return $this->wrapError($result);
        $this->inclPerm();
        if (($result = Permission::canPostChat(
            $this->account['id'],
            $this->formated['chat']
        )) !== true) return $this->wrapError($result);
        
        $this->inclDb('ChatEntry');
        $entry = ChatEntry::addEntry(
            $this->formated['chat'],
            $this->account['id'],
            $this->formated['text']
        );
        return $this->wrapResult($entry);
    }

    public function startVoting() {
        if (($result = $this->getAccount()) !== true)
            return $this->wrapError($result);
        if (($result = $this->getData(array(
            'chat' => 'int',
            'voteKey' => [ 'regex', '/^.{1,5}$/']
        ))) !== true)
            return $this->wrapError($result);
        $this->inclPerm();
        if (($result = Permission::canStartVoting(
            $this->account['id'],
            $this->formated['chat'],
            $this->formated['voteKey']
        )) !== true) return $this->wrapError($result);
        
        $this->inclDb('VoteSetting','GameGroup','ChatRoom');
        $this->inclRolH();
        $voting = VoteSetting::create(
            $this->formated['chat'],
            $this->formated['voteKey']
        );
        $chat = ChatRoom::create($this->formated['chat']);
        $game = GameGroup::create($chat->game);
        $roleH = new RoleHandler($game);
        $roleH->startVoting($voting);
        return $this->wrapResult($voting);
    }

    public function finishVoting() {
        if (($result = $this->getAccount()) !== true)
            return $this->wrapError($result);
        if (($result = $this->getData(array(
            'chat' => 'int',
            'voteKey' => [ 'regex', '/^.{1,5}$/']
        ))) !== true)
            return $this->wrapError($result);
        $this->inclPerm();
        if (($result = Permission::canFinishVoting(
            $this->account['id'],
            $this->formated['chat'],
            $this->formated['voteKey']
        )) !== true) return $this->wrapError($result);
        
        $this->inclDb('VoteSetting','GameGroup','ChatRoom');
        $this->inclRolH();
        $voting = VoteSetting::create(
            $this->formated['chat'],
            $this->formated['voteKey']
        );
        $chat = ChatRoom::create($this->formated['chat']);
        $game = GameGroup::create($chat->game);
        $roleH = new RoleHandler($game);
        $roleH->finishSingleVoting($voting);
        return $this->wrapResult(true);
    }

    public function vote() {
        if (($result = $this->getAccount()) !== true)
            return $this->wrapError($result);
        if (($result = $this->getData(array(
            'chat' => 'int',
            'voteKey' => [ 'regex', '/^.{1,5}$/'],
            'target' => 'int'
        ))) !== true)
            return $this->wrapError($result);
        $this->inclPerm();


        $this->inclDb('VoteSetting','VoteEntry','ChatRoom','GameGroup','User');
        $voting = VoteSetting::create(
            $this->formated['chat'],
            $this->formated['voteKey']
        );
        $chat = ChatRoom::create($this->formated['chat']);
        $game = GameGroup::create($chat->game);
        foreach (User::loadAllUserByGroup($game->mainGroupId) as $user)
            if ($user->user == $this->account['id'])
                $playerId = $user->player->id;
        if (!isset($playerId))
            return $this->wrapError($this->errorId('user not found'));


        if (($result = Permission::canVote(
            $playerId,
            $this->formated['chat'],
            $this->formated['voteKey'],
            $this->formated['target']
        )) !== true) return $this->wrapError($result);
        

        $vote = VoteEntry::createVote(
            $voting,
            $playerId,
            $this->formated['target']
        );
        return $this->wrapResult($vote);
    }

    public function setConfig() {
        if (($result = $this->getAccount()) !== true)
            return $this->wrapError($result);
        if (($result = $this->getData(array(
            'config' => ['regex', '/^.{1,1000}$/']
        ))) !== true)
            return $this->wrapError($result);

        $this->inclDb('UserConfig');
        $conf = UserConfig::createNewConfig(
            $this->account['id'],
            $this->formated['config']
        );
        return $this->wrapResult($conf->config);
    }
}