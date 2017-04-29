<?php

include_once dirname(__FILE__).'/../db.php';
include_once dirname(__FILE__).'/../VoteSetting/VoteSetting.php';

class ChatRoom {
	//the id of this chatroom
	public $id;
	//the game of this chatroom
	public $game;
	//the chat mode of this chatroom - its the access key for the player
	public $chatMode;
	//say if the chatroom is opened - if not, then its readonly
	public $opened;
	//the connected voting
	public $voting;
	
	public function __construct($id) {
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/loadChatRoom.sql',
			array(
				"id" => $id
			)
		);
		if ($entry = $result->getResult()->getEntry()) {
			$this->id = $entry["Id"];
			$this->game = $entry["Game"];
			$this->chatMode = $entry["ChatMode"];
			$this->opened = boolval($entry["Opened"]);
		}
		$result->free();
		$this->voting = new VoteSetting($this->id);
		if ($this->voting->chat === null)
			$this->voting = null;
	}
	
	public static function createChatRoom($game, $mode) {
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/createChatRoom.sql',
			array(
				"game" => $game,
				"mode" => $mode
			)
		);
		$result->getResult->free();
		$entry = $result->getResult->getEntry();
		$result->free();
		return new ChatRoom($entry["Id"]);
	}
	
	public function changeOpenedState($opened) {
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/changeOpenedState.sql',
			array(
				"opened" => $this->opened = $opened,
				"id" => $this->id
			)
		);
		$result->free();
	}

	public function createVoting($end) {
		$this->voting = VoteSetting::createVoteSetting($this->id, $end);
	}
}