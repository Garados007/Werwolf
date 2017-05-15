<?php

include_once dirname(__FILE__).'/../db.php';
include_once dirname(__FILE__).'/../JsonExport/JsonExport.php';

class User extends JsonExport {
	//group id
	public $group;
	//user id
	public $user;
	//the time when the user was the last time online
	public $lastOnline;
	
	public function __construct($group, $user, $lastOnline) {
		$this->jsonNames = array('group','user','lastOnline');
		$this->group = $group;
		$this->user = $user;
		$this->lastOnline = $lastOnline;
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
			$list[] = new User($entry["GroupId"], 
				intval($entry["UserId"]), intval($entry["LastOnline"]));
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
			$list[] = new User(intval($entry["GroupId"]), 
				intval($entry["UserId"]), intval($entry["LastOnline"]));
		}
		$result->free();
		return $list;
	}
	
	public static function createUser($group, $user) {
		// var_dump($user);
		// debug_print_backtrace();
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/addUser.sql',
			array(
				"group" => is_numeric($group) ? $group : $group->id,
				"user" => is_numeric($user) ? $user : $user->user
			)
		);
		if ($result) $result->free();
		return new User($group, $user, 0);
	}
	
	public function remove() {
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/removeUser.sql',
			array(
				"group" => $this->group,
				"user" => $this->user
			)
		);
		$result->free();
	}
	
	public function setOnline($time) {
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/setLastOnline.sql',
			array(
				"group" => $this->group,
				"user" => $this->user,
				"time" => $this->lastOnline = $time
			)
		);
		$result->free();
	}
}