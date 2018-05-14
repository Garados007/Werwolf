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

	private static $cache = array();
	private function __construct() {}
	
	public static function create($chat, $voteKey) {
		if (isset(self::$cache[$chat]) && isset(self::$cache[$chat][$voteKey]))
			return self::$cache[$chat][$voteKey];
		$cur = new VoteSetting();

		$cur->jsonNames = array('chat', 'voteKey', 'created',
			'voteStart', 'voteEnd', 'enabledUser', 'targetUser',
			'result');
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/loadVoteSetting.sql',
			array(
				"chat" => $chat,
				"key" => DB::escape($voteKey)
			)
		);
		if ($entry = $result->getResult()->getEntry()) {
			$cur->chat = intval($entry["Chat"]);
			$cur->voteKey = $entry["VoteKey"];
			$cur->created = intval($entry["Created"]);
			$cur->voteStart = $entry["VoteStart"];
			$cur->voteEnd = $entry["VoteEnd"];
			$cur->enabledUser = explode(',', $entry["EnabledUser"]);
			$cur->targetUser = explode(',', $entry["TargetUser"]);
			$cur->result = $entry["ResultTarget"];
		}
		else $cur = null;
		$result->flush();

		if (!isset(self::$cache[$chat]))
			self::$cache[$chat] = array();
		return self::$cache[$chat][$voteKey] = $cur;
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
		return self::create($chat, $key);
	}

	private static $votCache = array();
	
	public static function getVotingKeysForChat($chatId) {
		if (isset(self::$votCache[$chatId]))
			return self::$votCache[$chatId];
		$keys = array();
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/getVotingKeys.sql',
			array(
				"chat" => $chatId
			)
		);
		$set = $result->getResult();
		while ($entry = $set->getEntry()) {
			$keys[] = $entry["VoteKey"];
		}
		$result->free();
		return self::$votCache[$chatId] = $keys;
	}

	public static function getAllVotings($chatId) {
		$result = array();
		foreach (self::getVotingKeysForChat($chatId) as $key)
			$result[] = self::create($chatId, $key);
		return $result;
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