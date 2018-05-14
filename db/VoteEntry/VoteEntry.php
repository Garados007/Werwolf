<?php

include_once dirname(__FILE__).'/../db.php';
include_once dirname(__FILE__).'/../VoteSetting/VoteSetting.php';
include_once dirname(__FILE__).'/../Player/Player.php';
include_once dirname(__FILE__).'/../JsonExport/JsonExport.php';

class VoteEntry extends JsonExport {
	//the vote setting id
	public $setting;
	//the key of the voting
	public $voteKey;
	//the user id who votes
	public $voter;
	//the target id of the voting
	public $target;
	//the date of vote
	public $date;
	
	public function __construct($setting, $key, $voter, $target, $date) {
		$this->jsonNames = array('setting', 'voteKey', 'voter', 
			'target', 'date');
		$this->setting = $setting;
		$this->voteKey = $key;
		$this->voter = $voter;
		$this->target = $target;
		$this->date = $date;
	}
	
	public static function getVotesBySetting(VoteSetting $setting) {
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/loadVotesOfSetting.sql',
			array(
				"setting" => $setting->chat,
				"key" => $setting->voteKey
			)
		);
		$list = array();
		$set = $result->getResult();
		while ($entry = $set->getEntry()) {
			$list[] = new VoteEntry($entry["Setting"], $entry["VoteKey"],
				$entry["Voter"], $entry["Target"], $entry["VoteDate"]);
		}
		$result->free();
		return $list;
	}
	
	public static function getVoteByUser(VoteSetting $setting, $player) {
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/loadVotesOfUser.sql',
			array(
				"setting" => $setting->chat,
				"key" => $setting->voteKey,
				"user" => is_numeric($player) ? $player : $player->user
			)
		);
		$item = null;
		$set = $result->getResult();
		if ($entry = $set->getEntry()) {
			$item = new VoteEntry($entry["Setting"], $entry["VoteKey"],
				$entry["Voter"], $entry["Target"], $entry["VoteDate"]);
			$set->free();
		}
		$result->free();
		return $item;
	}
	
	public static function createVote(VoteSetting $setting, $user, $target) {
		$date = time();
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/addVote.sql',
			array(
				"setting" => $setting->chat,
				"key" => $setting->voteKey,
				"voter" => is_numeric($user) ? $user : $user->user,
				"target" => is_numeric($target) ? $target : $target->user,
				"date" => $date
			)
		);
		$result->free();
		return new VoteEntry(
			$setting->chat, $setting->voteKey,
			is_numeric($user) ? $user : $user->user, 
			is_numeric($target) ? $target : $target->user, $date);
	}
}