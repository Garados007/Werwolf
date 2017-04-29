<?php

include_once dirname(__FILE__).'/../db.php';

class VoteEntry {
	//the vote setting id
	public $setting;
	//the user who votes
	public $voter;
	//the target of the voting
	public $target;
	//the date of vote
	public $date;
	
	public function __construct($setting, $voter, $target, $date) {
		$this->setting = $setting;
		$this->voter = $voter;
		$this->target = $target;
		$this->date = $date;
	}
	
	public static function getVotesBySetting($setting) {
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/loadVotesOfSetting.sql',
			array(
				"setting" => $setting
			)
		);
		$list = array();
		$set = $result->getResult();
		while ($entry = $set->getEntry()) {
			$list[] = new VoteEntry($entry["Setting"], $entry["Voter"],
				$entry["Target"], $entry["VoteDate"]);
		}
		$result->free();
		return $list;
	}
	
	public static function getVoteByUser($setting, $user) {
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/loadVotesOfUser.sql',
			array(
				"setting" => $setting,
				"user" => $user
			)
		);
		$item;
		$set = $result->getResult();
		if ($entry = $set->getEntry()) {
			$list = new VoteEntry($entry["Setting"], $entry["Voter"],
				$entry["Target"], $entry["VoteDate"]);
			$set->free();
		}
		$result->free();
		return $item;
	}
	
	public static function createVote($setting, $user, $target) {
		$date = time();
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/addVote.sql',
			array(
				"setting" => $setting,
				"voter" => $voter,
				"target" => $target,
				"date" => $date
			)
		);
		$result->free();
		return new VoteEntry($setting, $user, $target, $date);
	}
}