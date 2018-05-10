<?php

include_once dirname(__FILE__).'/../db.php';
include_once dirname(__FILE__).'/../VoteSetting/VoteSetting.php';
include_once dirname(__FILE__).'/../JsonExport/JsonExport.php';

class ChatRoom extends JsonExport {
	//the id of this chatroom
	public $id;
	//the game of this chatroom
	public $game;
	//the chat mode of this chatroom - its the access key for the player
	public $chatRoom;
	//the connected voting
	public $voting;

	private static $cache = array();

	private function __construct() {}
	
	public static function create($id) {
		if (isset(self::$cache[$id]))
			return self::$cache[$id];

		$cur = new ChatRoom();
		$cur->jsonNames = array('id', 'game', 'chatMode', 'voting');
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/loadChatRoom.sql',
			array(
				"id" => $id
			)
		);
		if ($entry = $result->getResult()->getEntry()) {
			$cur->id = $entry["Id"];
			$cur->game = $entry["Game"];
			$cur->chatRoom = $entry["ChatRoom"];
			$result->free();
			$cur->voting = new VoteSetting($cur->id);
			if ($cur->voting->chat === null)
				$cur->voting = null;
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
	
	public function createVoting($end) {
		$this->voting = VoteSetting::createVoteSetting($this->id, $end);
	}
}