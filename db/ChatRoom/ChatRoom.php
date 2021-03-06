<?php

include_once dirname(__FILE__).'/../db.php';
include_once dirname(__FILE__).'/../JsonExport/JsonExport.php';
include_once dirname(__FILE__).'/../VoteSetting/VoteSetting.php';
include_once __DIR__ . '/../ChatPermission/ChatPermission.php';

class ChatRoom extends JsonExport {
	//the id of this chatroom
	public $id;
	//the game of this chatroom
	public $game;
	//the chat mode of this chatroom - its the access key for the player
	public $chatRoom;
	//the connected voting
	public $voting;
	//the current ChatPermission array with all permissions
	public $permission;

	private static $cache = array();

	private function __construct() {}
	
	public static function create($id) {
		if (isset(self::$cache[$id]))
			return self::$cache[$id];

		$cur = new ChatRoom();
		$cur->jsonNames = array('id', 'game', 'chatRoom', 'voting');
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/loadChatRoom.sql',
			array(
				"id" => $id
			)
		);
		if ($entry = $result->getResult()->getEntry()) {
			$cur->id = intval($entry["Id"]);
			$cur->game = intval($entry["Game"]);
			$cur->chatRoom = $entry["ChatRoom"];
			$result->free();
			$cur->voting = array();
			foreach (VoteSetting::getVotingKeysForChat($cur->id) as $key)
				$cur->voting[] = VoteSetting::create($cur->id, $key);
			$cur->permission = ChatPermission::loadPermissions($cur->id);
		}
		else {
			$result->free();
			$cur = null;
		}
		return self::$cache[$id] = $cur;
	}
	
	public static function createChatRoom($game, $mode) {
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/createChatRoom.sql',
			array(
				"game" => $game,
				"mode" => $mode
			)
		);
		if ($set = $result->getResult()) $set->free();
		echo DB::getError();
		$entry = $result->getResult()->getEntry();
		$result->free();
		return self::create($entry["Id"]);
	}
	
	public static function getChatRoomId($game, $room) {
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/getChatRoomId.sql',
			array(
				"game" => $game,
				"mode" => $room
			)
		);
		if ($entry = $result->getResult()->getEntry())
			return $entry["Id"];
	}

	public static function getAllChatRoomIds($game) {
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/getAllChatRoomIds.sql',
			array(
				"game" => $game
			)
		);
		$set = $result->getResult();
		$res = array();
		while ($entry = $set->getEntry())
			$res[] = intval($entry["Id"]);
		$result->free();
		return $res;
	}
	
	public function createVoting($key, $start, $end, array $enabled, 
		array $target) 
	{
		$voting = VoteSetting::createVoteSetting($this->id, $key, $start,
			$end, $enabled, $target);
		$this->voting[] = $voting;
		return $voting;
	}

	public function deleteVoting($key) {
		$voting = array();
		foreach ($this->voting as &$v)
			if ($v->voteKey == $key)
				$v->deleteVoting();
			else $voting[] = $v;
		$this->voting = $voting;
	}

	public function getPermission($key) {
		foreach ($this->permission as $perm)
			if ($perm->roleKey == $key)
				return $perm;
		return null;
	}

	public function addPermission(ChatPermission $permission) {
		ChatPermission::addPermissions($permission);
		$list = array();
		foreach ($this->permission as &$perm)
			if ($perm->roleKey !== $permission->roleKey)
				$list[] = &$perm;
		$list[] = $permission;
		$this->permission = $list;
	}
}