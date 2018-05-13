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
        return $this->wrapResult($user);
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
            if ($user->user == $this->formated['user'])
                return $this->wrapResult($user);
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
        return $this->wrapResult($user);
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
}