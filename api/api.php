<?php

include_once dirname(__FILE__).'/../logic/Game/Game.php';
include_once dirname(__FILE__).'/../logic/Chat/Chat.php';
include_once dirname(__FILE__).'/../account/manager.php';

class Api {
	public $params;
	
	public $result;
	
	public $error;
	
	public $errorKey;
	
	public function __construct($params) {
		$this->params = $params;
		//$this->wrapAction();
		$this->work();
	}
	
	public function exportResult() {
		if ($this->error !== null) {
			return json_encode(array(
				"success" => false,
				"error" => $this->error,
				"errorkey" => $this->errorKey,
				"request" => $this->params
			));
		}
		else {
			return json_encode(array(
				"success" => true,
				"result" => $this->result
			));
		}
	}
	
	private function wrapAction() {
		ob_start();
		$this->work();
		$output = ob_get_contents();
		ob_end_clean();
		if ($output != '') {
			$this->error = $output;
			$this->errorKey = 'unknown output';
		}
	}
	
	private function getStr($name) {
		return strval($this->params[$name]);
	}
	
	private function getInt($name) {
		return intval($this->params[$name]);
	}
	
	private function getStrArray($name) {
		if (!is_array($this->params[$name]))
			return array(strval($this->params[$name]));
		$list = array();
		foreach ($this->params[$name] as $value)
			$list[] = strval($value);
		return $list;
	}
	
	private function check($names) {
		foreach ($names as $name) {
			if (!isset($this->params[$name])) {
				$this->error = "missing parameter '$$name'";
				return false;
			}
		}
		return true;
	}
	
	private function work() {
		if (!$this->check(['mode'])) return;
		switch ($this->params["mode"]) {
			case "multi": $this->multi(); break;
			case "getAccountState": $this->getAccountState(); break;
			case "getAccountName": $this->getAccountName(); break;
			case "createGroup": $this->createGroup(); break;
			case "getGroup": $this->getGroup(); break;
			case "addUserToGroup": $this->addUserToGroup(); break;
			case "addUserToGroupByKey": $this->addUserToGroupByKey(); break;
			case "getUserFromGroup": $this->getUserFromGroup(); break;
			case "setUserOnline": $this->setUserOnline(); break;
			case "getGroupFromUser": $this->getGroupFromUser(); break;
			case "removeCurrentGame": $this->removeCurrentGame(); break;
			case "createGame": $this->createGame(); break;
			case "getGame": $this->getGame(); break;
			case "nextRound": $this->nextRound(); break;
			case "checkIfFinished": $this->checkIfFinished(); break;
			case "getPlayer": $this->getPlayer(); break;
			case "getChatMode": $this->getChatMode(); break;
			case "getChatRoomId": $this->getChatRoomId(); break;
			case "getAccessibleChatRooms": $this->getAccessibleChatRooms(); break;
			case "getChatRoom": $this->getChatRoom(); break;
			case "getPlayerInRoom": $this->getPlayerInRoom(); break;
			case "getLastChat": $this->getLastChat(); break;
			case "addChat": $this->addChat(); break;
			case "createVoting": $this->createVoting(); break;
			case "endVoting": $this->endVoting(); break;
			case "deleteVoting": $this->deleteVoting(); break;
			case "addVote": $this->addVote(); break;
			case "getVotesFromRoom": $this->getVotesFromRoom(); break;
			case "getVoteFromPlayer": $this->getVoteFromPlayer(); break;
			
			
			default: $this->error = "not supported mode ".$this->params["mode"]; break;
		}
	}
	
	//Multirequest
	
	private function multi() {
		if (!$this->check(['tasks'])) return;
		$tasks = $this->params['tasks'];
		if (!is_array($tasks)) {
			$this->error = "tasks is not an array";
			return;
		}
		$result = array();
		foreach ($tasks as $task) {
			$api = new Api(json_decode(json_decode($task, true), true));
			$result[] = $api->exportResult();
		}
		$this->result = array(
			"method" => 'multi',
			"results" => $result
		);
	}
	
	//Account functions
	
	private function getAccountState() {
		$state = AccountManager::GetCurrentAccountData();
		$this->result = array(
			"method" => 'getAccountState',
			"state" => $state
		);
	}
	
	private function getAccountName() {
		if (!$this->check(['user'])) return;
		$name = AccountManager::GetAccountName(
			$this->getInt("user")
		);
		$this->result = array(
			"method" => 'getAccountName',
			"user" => $this->getInt("user"),
			"name" => $name
		);
	}
	
	//Group functions
	
	private function createGroup() {
		if (!$this->check(['name', 'user'])) return;
		$group = Game::CreateGroup(
			$this->getStr("name"),
			$this->getInt("user")
		); 
		$user = Game::AddUserToGroup(
			$this->getInt("user"),
			$group
		);
		$this->result = array(
			"method" => 'createGroup',
			"group" => $group->exportJson(),
			"user" => $user->exportJson()
		);
	}
	
	private function getGroup() {
		if (!$this->check(['group'])) return;
		$group = Game::GetGroup(
			$this->getInt('group')
		);
		$this->result = array(
			"method" => 'getGroup',
			"group" => $group->exportJson()
		);
	}
	
	private function addUserToGroup() {
		if (!$this->check(['user', 'group'])) return;
		$user = Game::AddUserToGroup(
			$this->getInt("user"),
			$this->getInt("group")
		);
		$this->result = array(
			"method" => 'addUserToGroup',
			"user" => $user->exportJson()
		);
	}
	
	private function addUserToGroupByKey() {
		if (!$this->check(['user','key'])) return;
		$group = Game::GetGroupByKey(
			$this->getStr('key')
		);
		$user = $group == null ? null : Game::AddUserToGroup(
			$this->getInt('user'),
			$group->id
		);
		$this->result = array(
			"method" => "addUserToGroupByKey",
			"success" => $user != null,
			"group" => $group == null ? null : $group->exportJson(),
			"user" => $user == null ? null : $user->exportJson()
		);
	}
	
	private function getUserFromGroup() {
		if (!$this->check(['group'])) return;
		$list = Game::GetAllUserFromGroup(
			$this->getInt('group')
		);
		$this->result = array(
			"method" => 'getUserFromGroup',
			"group" => $this->getInt('group'),
			"user" => $list
		);
	}
	
	private function setUserOnline() {
		if (!$this->check(['group','user'])) return;
		$list = User::loadAllUserByGroup(
			$this->getInt('group')
		);
		$res = array();
		$user = $this->getInt('user');
		for ($i = 0; $i < count($list); ++$i) {
			if ($list[$i]->user == $user)
				$list[$i]->setOnline(time());
			$res[] = $list[$i]->exportJson();
		}
		$this->result = array(
			"method" => 'setUserOnline',
			"group" => $this->getInt('group'),
			"user" => $res
		);
	}
	
	private function getGroupFromUser() {
		if (!$this->check(['user'])) return;
		$list = Game::GetUserGroups(
			$this->getInt('user')
		);
		$this->result = array(
			"method" => 'getGroupFromUser',
			"user" => $this->getInt('user'),
			"group" => $list
		);
	}
	
	private function removeCurrentGame() {
		if (!$this->check(['group'])) return;
		$group = Game::GetGroup(
			$this->getInt('group')
		);
		$group->setCurrentGame(null);
		$this->result = array(
			"method" => 'removeCurrentGame',
			"group" => $group->exportJson()
		);
	}
	
	//Game functions
	
	private function createGame() {
		if (!$this->check(['group','roles'])) return;
		$game = Game::CreateGame(
			$this->getInt('group'),
			$this->getStrArray('roles')
		);
		$this->result = array(
			"method" => 'createGame',
			"group" => $this->getInt('group'),
			"game" => $game->exportJson()
		);
	}
	
	private function getGame() {
		if (!$this->check(['game'])) return;
		$game = Game::GetGame(
			$this->getInt('game')
		);
		$this->result = array(
			"method" => 'getGame',
			"game" => $game->exportJson()
		);
	}
	
	private function nextRound() {
		if (!$this->check(['game'])) return;
		$game = Game::NextRound(
			$this->getInt('game')
		);
		$this->result = array(
			"method" => 'nextRound',
			"game" => $game->exportJson()
		);
	}
	
	private function checkIfFinished() {
		if (!$this->check(['game'])) return;
		$finished = Game::CheckIfFinished(
			$this->getInt('game')
		);
		$this->result = array(
			"method" => 'checkIfFinished',
			"game" => $this->getInt('game'),
			"finished" => $finished
		);
	}
	
	//Player functions
	
	private function getPlayer() {
		if (!$this->check(['game','user','me'])) return;
		$player = Game::getPlayer(
			$this->getInt('game'),
			$this->getInt('user')
		);
		$me = Game::getPlayer(
			$this->getInt('game'),
			$this->getInt('me')
		);
		VisibleRole::filterRoles($me, $player);
		$this->result = array(
			"method" => "getPlayer",
			"player" => $player->exportJson()
		);
	}
	
	//Chat functions
	
	private function getChatMode() {
		if (!$this->check(['cmode','role'])) return;
		$chatMode = Chat::GetChatMode(
			$this->getStr('cmode'),
			$this->getStr('role')
		);
		$this->result = array(
			"method" => "getChatMode",
			"chatMode" => $chatMode->exportJson()
		);
	}
	
	private function getChatRoomId() {
		if (!$this->check(['game','cmode'])) return;
		$id = Chat::GetChatRoomId(
			$this->getInt('game'),
			$this->getStr('cmode')
		);
		$this->result = array(
			"method" => "getChatRoomId",
			"game" => $this->getInt('game'),
			"mode" => $this->getStr('cmode'),
			"id" => $id
		);
	}
	
	private function getAccessibleChatRooms() {
		if (!$this->check(['game','user'])) return;
		$player = Game::getPlayer(
			$this->getInt('game'),
			$this->getInt('user')
		);
		$rooms = Chat::GetAccessibleChatRooms($player);
		$list = array();
		foreach($rooms as $key => $value) 
			$list[$key] = $value->exportJson();
		$this->result = array(
			"method" => "getAccessibleChatRooms",
			"player" => $player->exportJson(),
			"rooms" => $list
		);
	}
	
	private function getChatRoom() {
		if (!$this->check(['chat'])) return;
		$chat = Chat::GetChatRoom(
			$this->getInt('chat')
		);
		$this->result = array(
			"method" => "getChatRoom",
			"chat" => $chat->exportJson()
		);
	}
	
	private function getPlayerInRoom() {
		if (!$this->check(['chat','me'])) return;
		$players = Chat::GetPlayerInRoom(
			$this->getInt('chat')
		);
		$list = array();
		$room = Chat::GetChatRoom($this->getInt('chat'));
		$me = Game::getPlayer($room->game, $this->getInt('me'));
		foreach ($players as $player) {
			VisibleRole::filterRoles($me, $player);
			$list[] = $player->exportJson();
		}
		$this->result = array(
			"method" => "getPlayerInRoom",
			"chat" => $this->getInt('chat'),
			"player" => $list
		);
	}
	
	private function getLastChat() {
		if (!$this->check(['chat', 'since'])) return;
		$chat = Chat::GetLastChat(
			$this->getInt('chat'),
			$this->getInt('since')
		);
		$list = array();
		foreach ($chat as $c)
			$list[] = $c->exportJson();
		$this->result = array(
			"method" => "getLastChat",
			"since" => $this->getInt('since'),
			"room" => $this->getInt('chat'),
			"chat" => $list
		);
	}
	
	private function addChat() {
		if (!$this->check(['chat','user','text'])) return;
		$chat= Chat::AddChat(
			$this->getInt('chat'),
			$this->getInt('user'),
			$this->getStr('text')
		);
		$this->result = array(
			"method" => 'addChat',
			"room" => $this->getInt('chat'),
			"chat" => $chat->exportJson()
		);
	}
	
	private function createVoting() {
		if (!$this->check(['chat','end'])) return;
		$voting = Chat::CreateVoting(
			$this->getInt('chat'),
			$this->getInt('end')
		);
		$this->result = array(
			"method" => 'createVoting',
			"room" => $this->getInt('chat'),
			"voting" => $voting->exportJson()
		);
	}
	
	private function endVoting() {
		if (!$this->check(['chat'])) return;
		$result = Chat::EndVoting(
			$this->getInt('chat')
		);
		$this->result = array(
			"method" => 'endVoting',
			"room" => $this->getInt('chat'),
			"result" => $result
		);
	}
	
	private function deleteVoting() {
		if (!$this->check(['chat'])) return;
		Chat::DeleteVoting(
			$this->getInt('chat')
		);
		$this->result = array(
			"method" => 'deleteVoting',
			"room" => $this->getInt('chat')
		);
	}
	
	private function addVote() {
		if (!$this->check(['chat','user','target'])) return;
		$vote = Chat::AddVote(
			$this->getInt('chat'),
			$this->getInt('user'),
			$this->getInt('target')
		);
		$this->result = array(
			"method" => 'addVote',
			"vote" => $vote->exportJson()
		);
	}
	
	private function getVotesFromRoom() {
		if (!$this->check(['chat'])) return;
		$votes = Chat::GetVotesFromRoom(
			$this->getInt('chat')
		);
		$list = array();
		foreach ($votes as $vote) $list[] = $vote->exportJson();
		$this->result = array(
			"method" => 'getVotesFromRoom',
			"room" => $this->getInt('chat'),
			"votes" => $list
		);
	}
	
	private function getVoteFromPlayer() {
		if (!$this->check(['chat','user'])) return;
		$vote = Chat::GetVoteFromPlayer(
			$this->getInt('chat'),
			$this->getInt('user')
		);
		$this->result = array(
			"method" => 'getVoteFromPlayer',
			"chat" => $this->getInt('chat'),
			"vote" => $vote == null ? null : $vote->exportJson()
		);
	}
}