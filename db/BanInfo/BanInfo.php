<?php

include_once dirname(__FILE__).'/../db.php';
include_once dirname(__FILE__).'/../User/User.php';
include_once dirname(__FILE__).'/../JsonExport/JsonExport.php';

class BanInfo extends JsonExport {
	//the user that was banned
	public $user;
	//the spoker who created the ban
	public $spoker;
	//the group id where the user was banned from
	public $group;
	//the date where the ban starts
	public $startDate;
	//the date when the ban should end or null for never
	public $endDate;
	//the comment to this ban
	public $comment;
	
	public function __construct($user, $spoker, $group, $startDate, $endDate, $comment) {
		$this->jsonNames = array('user', 'spoker', 'group', 'startDate', 'endDate', 'comment');
		$this->user = $user;
		$this->spoker = $spoker;
		$this->group = $group;
		$this->startDate = $startDate;
		$this->endDate = $endDate;
		$this->comment = $comment;
	}

	private static function loadEntry($entry) {
		return new BanInfo(
			intval($entry['User']),
			intval($entry['Spoker']),
			intval($entry['GroupId']),
			intval($entry['StartDate']),
			intvaln($entry['EndDate']),
			strval($entry['Comment'])
		);
	}
	
	public static function getAllBansOfUser($userid) {
		$list = array();
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/load.sql',
			array(
				'mode' => 'fromUser',
				'user' => $userid
			)
		);
		$set = $result->getResult();
		while ($entry = $set->getEntry()) {
			$list[] = self::loadEntry($entry);
		}
		$result->free();
		return $list;
	}

	public static function getNewestBans() {
		$list = array();
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/load.sql',
			array(
				'mode' => 'newest'
			)
		);
		$set = $result->getResult();
		while ($entry = $set->getEntry()) {
			$list[] = self::loadEntry($entry);
		}
		$result->free();
		return $list;
	}
	
	public static function getOldestBans() {
		$list = array();
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/load.sql',
			array(
				'mode' => 'oldest'
			)
		);
		$set = $result->getResult();
		while ($entry = $set->getEntry()) {
			$list[] = self::loadEntry($entry);
		}
		$result->free();
		return $list;
	}
	
	public static function getUserSpokenBans($userid) {
		$list = array();
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/load.sql',
			array(
				'mode' => 'spokenBy',
				'user' => $userid
			)
		);
		$set = $result->getResult();
		while ($entry = $set->getEntry()) {
			$list[] = self::loadEntry($entry);
		}
		$result->free();
		return $list;
	}

	
	public static function getBansFromGroup($groupId) {
		$list = array();
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/load.sql',
			array(
				'mode' => 'forGroup',
				'group' => $groupId
			)
		);
		$set = $result->getResult();
		while ($entry = $set->getEntry()) {
			$list[] = self::loadEntry($entry);
		}
		$result->free();
		return $list;
	}

	public static function getSpecific($userid, $groupId) {
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/load.sql',
			array(
				'mode' => 'specific',
				'user' => $userid,
				'group' => $groupId
			)
		);
		$res = null;
		$set = $result->getResult();
		if ($entry = $set->getEntry()) {
			$res = self::loadEntry($entry);
		}
		$result->free();
		return $res;
	}

	//if $comment == null then this command would kick instead of ban
	//$end == null means perma ban, is_int($end) == true means temporary ban
	public static function addBan($user, $spoker, $group, $end, $comment) {
		$profile = User::loadSingle($user, $group);
		if ($profile === null) 
			return self::getSpecific($user, $group);
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/addBan.sql',
			array(
				'user' => $user,
				'spoker' => $spoker,
				'group' => $group,
				'end' => $end,
				'comment' => $comment,
				'kick' => $comment === null,
				'player' => $profile->player !== null ? 
					$profile->player->id : null
			)
		);
		echo DB::getError();
		$result->free();
		echo DB::getError();
		return self::getSpecific($user, $group);
	}

	public function revoke() {
		$now = time();
		$paid = $this->endDate === null ? 0 :
			floor(($this->endDate - $this->startDate) / 86400);
		$cost = floor(($now - $this->startDate) / 86400);
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/revoke.sql',
			array(
				'user' => $this->user,
				'group' => $this->group,
				'days' => $cost - $paid,
				'perma' => $this->endDate === null
			)
		);
		echo DB::getError();
		$result->free();
		$this->endDate = $now;
	}
}