<?php

include_once dirname(__FILE__).'/../db.php';
include_once dirname(__FILE__).'/../JsonExport/JsonExport.php';

class VoteSetting extends JsonExport {
	//the chat id where this voting is asigned
	public $chat;
	//the vote key to identify this voting in the chat
	public $voteKey;
	//the creation time of this voting.
	public $created;
	//the start date when this voting starts
	public $voteStart;
	//the end date when this voting ends or null for no ending
	public $voteEnd;
	//the list of user that are enabled to vote for this chat.
	//others can only see the results.
	public $enabledUser;
	//the list of all users that can be a vote target.
	public $targetUser;
	//The result of this voting
	public $result;
	
	public function __construct($chat, $voteKey) {
		$this->jsonNames = array('chat', 'voteKey', 'created',
			'voteStart', 'voteEnd', 'enabledUser', 'targetUser',
			'result');
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/loadVoteSetting.sql',
			array(
				"chat" => $chat,
				"key" => $key
			)
		);
		if ($entry = $result->getResult()->getEntry()) {
			$this->chat = intval($entry["Chat"]);
			$this->voteKey = $entry["VoteKey"];
			$this->created = intval($entry["Created"]);
			$this->voteStart = $entry["VoteStart"];
			$this->voteEnd = $entry["VoteEnd"];
			$this->enabledUser = explode(',', $entry["EnabledUser"]);
			$this->targetUser = explode(',', $entry["TargetUser"]);
			$this->result = $entry["ResultTarget"];
		}
		$result->flush();
	}
	
	public static function createVoteSetting($chat, $key, $start, $end, 
		array $enabled, array $target) 
	{
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/createVoteSetting.sql',
			array(
				"chat" => $chat,
				"key" => $key,
				"start" => $start,
				"end" => $end,
				"enabled" => $enabled,
				"target" => $target
			)
		);
		$result->free();
		return new VoteSetting($chat, $key);
	}
	
	public function startVoting() {
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/startVoting.sql',
			array(
				"start" => $this->voteStart = time(),
				"chat" => $this->chat,
				"key" => $this->voteKey
			)
		);
		$result->free();
	}

	public function endVoting($voteResult) {
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/endVoting.sql',
			array(
				"end" => $this->voteEnd = time(),
				"result" => $this->result = $voteResult,
				"chat" => $this->chat,
				"key" => $this->voteKey
			)
		);
		$result->free();
	}
	
	public function deleteVoting() {
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/deleteVoteSetting.sql',
			array(
				"chat" => $this->chat,
				"key" => $this->voteKey
			)
		);
	}
}