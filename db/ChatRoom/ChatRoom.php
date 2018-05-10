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
	
	public function __construct($id) {
		$this->jsonNames = array('id', 'game', 'chatMode', 'voting');
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/loadChatRoom.sql',
			array(
				"id" => $id
			)
		);
		if ($entry = $result->getResult()->getEntry()) {
			$this->id = $entry["Id"];
			$this->game = $entry["Game"];
			$this->chatRoom = $entry["ChatRoom"];
			$result->free();
			$this->voting = new VoteSetting($this->id);
			if ($this->voting->chat === null)
				$this->voting = null;
		}
		else $result->free();
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
		return new ChatRoom($entry["Id"]);
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