<?php

include_once dirname(__FILE__).'/../logic/Game/Game.php';
include_once dirname(__FILE__).'/../logic/Chat/Chat.php';

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
				"errorkey" => $this->errorKey
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
			case "createGroup": $this->createGroup(); break;
			case "getGroup": $this->getGroup(); break;
			case "addUserToGroup": $this->addUserToGroup(); break;
			case "getUserFromGroup": $this->getUserFromGroup(); break;
			case "getGroupFromUser": $this->getGroupFromUser(); break;
			case "createGame": $this->createGame(); break;
			case "getGame": $this->getGame(); break;
			case "getPlayer": $this->getPlayer(); break;
			case "getChatMode": $this->getChatMode(); break;
			case "getChatRoomId": $this->getChatRoomId(); break;
			case "getAccessibleChatRooms": $this->getAccessibleChatRooms(); break;
			case "getChatRoom": $this->getChatRoom(); break;
			case "getPlayerInRoom": $this->getPlayerInRoom(); break;
			
			
			default: $this->error = "not supported mode"; break;
		}
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

	//Player functions
	
	private function getPlayer() {
		if (!$this->check(['game','user'])) return;
		$player = Game::getPlayer(
			$this->getInt('game'),
			$this->getInt('user')
		);
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
		if (!$this->check(['chat'])) return;
		$players = Chat::GetPlayerInRoom(
			$this->getInt('chat')
		);
		$list = array();
		foreach ($players as $player)
			$list[] = $player->exportJson();
		$this->result = array(
			"method" => "getPlayerInRoom",
			"chat" => $this->getInt('chat'),
			"player" => $list
		);
	}
}