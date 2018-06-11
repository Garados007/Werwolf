<?php

include_once dirname(__FILE__).'/../db.php';
include_once dirname(__FILE__).'/../JsonExport/JsonExport.php';
include_once __DIR__ . '/../Player/Player.php';
include_once __DIR__ . '/../UserStats/UserStats.php';

class User extends JsonExport {
	//group id
	public $group;
	//user id
	public $user;
	//current player
	public $player;
	//the current UserStats object
	public $stats;
	
	public function __construct($group, $user, $player) {
		$this->jsonNames = array('group','user','player','stats');
		$this->group = $group;
		$this->user = $user;
		$this->player = is_null($player) ? null :
			is_int($player) ? Player::create($player) : $player;
		$this->stats = UserStats::create($user);
	}
	
	public static function loadAllUserByGroup($group) {
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/loadAllUserByGroup.sql',
			array(
				"group" => $group
			)
		);
		$list = array();
		$set = $result->getResult();
		while ($entry = $set->getEntry()) {
			$list[] = new User(
				intval($entry["GroupId"]), 
				intval($entry["UserId"]), 
				intvaln($entry["Player"]));
		}
		$result->free();
		return $list;
	}
	
	public static function loadAllGroupsByUser($user) {
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/loadAllGroupsByUser.sql',
			array(
				"user" => $user
			)
		);
		$list = array();
		echo DB::getError();
		$set = $result->getResult();
		while ($entry = $set->getEntry()) {
			$list[] = new User(
				intval($entry["GroupId"]), 
				intval($entry["UserId"]), 
				intvaln($entry["Player"]));
		}
		$result->free();
		return $list;
	}

	public static function loadSingle($user, $group) {
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/loadSingle.sql',
			array(
				"user" => $user,
				"group" => $group
			)
		);
		$res = null;
		echo DB::getError();
		$set = $result->getResult();
		if ($entry = $set->getEntry()) {
			$res = new User(
				intval($entry["GroupId"]), 
				intval($entry["UserId"]), 
				intvaln($entry["Player"]));
		}
		$result->free();
		return $res;
	}
	
	public static function createUser($group, $user) {
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/addUser.sql',
			array(
				"group" => is_numeric($group) ? $group : $group->id,
				"user" => is_numeric($user) ? $user : $user->user
			)
		);
		if ($result) $result->free();
		return new User($group, $user, null);
	}
	
	public function remove() {
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/deleteUser.sql',
			array(
				"group" => $this->group,
				"user" => $this->user
			)
		);
		$result->getResult()->free();
		$entry = $result->getResult()->getEntry();
		$result->free();
		return intval($entry['count']) == 0;
	}
	
	public function setPlayer($player) {
		$this->player = is_null($player) ? null :
			is_int($player) ? Player::create($player) : $player;
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/setPlayer.sql',
			array(
				"group" => $this->group,
				"user" => $this->user,
				"player" => $this->player == null ? null : $this->player->id
			)
		);
		$result->free();
	}
}