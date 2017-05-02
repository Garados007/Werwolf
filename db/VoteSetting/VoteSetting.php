<?php

include_once dirname(__FILE__).'/../db.php';
include_once dirname(__FILE__).'/../JsonExport/JsonExport.php';

class VoteSetting extends JsonExport {
	//the chat id where this voting is asigned
	public $chat;
	//the start date when this voting starts
	public $voteStart;
	//the end date when this voting ends or null for no ending
	public $voteEnd;
	//The result of this voting
	public $result;
	
	public function __construct($chat) {
		$this->jsonNames = array('chat', 'voteStart', 'voteEnd', 'result');
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/loadVoteSetting.sql',
			array(
				"chat" => $chat
			)
		);
		if ($entry = $result->getResult()->getEntry()) {
			$this->chat = $entry["Chat"];
			$this->voteStart = $entry["VoteStart"];
			$this->voteEnd = $entry["VoteEnd"];
			$this->result = $entry["ResultTarget"];
		}
		$result->flush();
	}
	
	public static function createVoteSetting($chat, $end) {
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/createVoteSetting.sql',
			array(
				"chat" => $chat,
				"start" => time(),
				"end" => $end
			)
		);
		$result->free();
		return new VoteSetting($chat);
	}
	
	public function endVoting($voteResult) {
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/endVoting.sql',
			array(
				"end" => $this->voteEnd = time(),
				"result" => $this->result = $voteResult,
				"chat" => $this->chat
			)
		);
		$result->free();
	}
	
	public function deleteVoting() {
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/deleteVoteSetting.sql',
			array(
				"chat" => $this->chat
			)
		);
	}
}