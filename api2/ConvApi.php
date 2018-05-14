<?php

include_once __DIR__ . '/ApiBase.php';

class ConvApi extends ApiBase {
    public function lastOnline() {
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
            
        $this->inclDb('User', 'UserStats');
        $result = array();
        foreach (User::loadAllUserByGroup(
            $this->formated['group']
        ) as $user)
            $result[] = array(
                $user->user, 
                $user->stats->lastOnline
            );
        return $this->wrapResult($result);
    }

    public function getUpdatedGroup() {
        if (($result = $this->getAccount()) !== true)
            return $this->wrapError($result);
        if (($result = $this->getData(array(
            'group' => 'int',
            'lastChange' => 'int',
            'leader' => 'int',
            '?phase' => [ 'regex', '/^.{1,8}$/' ],
            '?day' => 'int'
        ))) !== true)
            return $this->wrapError($result);
        $this->inclPerm();
        if (($result = Permission::canGetGroupData(
            $this->account['id'],
            $this->formated['group']
        )) !== true) return $this->wrapError($result);

        if (isset($this->formated['phase']) ^ isset($this->formated['day']))
            return $this->wrapError($this->errorFormat('key phase and day need to be defined together'));
        $this->inclDb('Group', 'GameGroup');
        $group = Group::create($this->formated['group']);
        if ($group === null)
            return $this->wrapError($this->errorId('group not found'));
        $change = $this->formated['lastChange'];
        if ($group->created > $change ||
            ($group->lastTime !== null && $group->lastTime > $change) ||
            ($group->currentGame !== null && (
                $group->currentGame->started > $change ||
                ($group->currentGame->finished !== null &&
                    $group->currentGame->finished > $change)
            )))
            return $this->wrapResult($group);
        if ($group->leader != $this->formated['leader'])
            return $this->wrapResult($group);
        if (isset($this->formated['phase']) ^ ($group->currentGame !== null))
            return $this->wrapResult($group);
        if (isset($this->formated['phase']) && (
            $group->currentGame->phase != $this->formated['phase'] ||
            $group->currentGame->day != $this->formated['day']
        ))
            return $this->wrapResult($group);
        return $this->wrapResult(null);
    }

    public function getChangedVotings() {
        if (($result = $this->getAccount()) !== true)
            return $this->wrapError($result);
        if (($result = $this->getData(array(
            'game' => 'int',
            'lastChange' => 'int'
        ))) !== true)
            return $this->wrapError($result);
        $this->inclDb('GameGroup', 'ChatRoom', 'VoteEntry', 'VoteSetting');
        $game = GameGroup::create($this->formated['game']);
        if ($game === null)
            return $this->wrapError($this->errorId('game not found'));
        
        $this->inclPerm();
        if (($result = Permission::canGetGroupData(
            $this->account['id'],
            $game->mainGroupId
        )) !== true) return $this->wrapError($result);
               
        $result = array();
        $change = $this->formated['lastChange'];
        foreach (ChatRoom::getAllChatRoomIds($game->id) as $id) {
            $chat = ChatRoom::create($id);
            foreach ($chat->voting as $voting)
                if ($voting->created > $change ||
                    ($voting->voteStart !== null && $voting->voteStart > $change) ||
                    ($voting->voteEnd !== null && $voting->voteEnd > $change))
                    $result[] = $voting;
        }
        return $this->wrapResult($result);
    }

    public function getNewChatEntrys() {
        if (($result = $this->getAccount()) !== true)
            return $this->wrapError($result);
        if (($result = $this->getData(array(
            'chat' => 'int',
            'after' => 'int'
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
            $this->formated['after']
        );
        return $this->wrapResult($result);
    }

    public function getNewVotes() {
        if (($result = $this->getAccount()) !== true)
            return $this->wrapError($result);
        if (($result = $this->getData(array(
            'chat' => 'int',
            'voteKey' => [ 'regex', '/^.{1,5}$/'],
            'lastChange' => 'int'
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
        $result = array();
        foreach (VoteEntry::getVotesBySetting($voting) as $vote)
            if ($vote->date > $this->formated['lastChange'])
                $result[] = $vote;
        return $this->wrapResult($result);
    }
}