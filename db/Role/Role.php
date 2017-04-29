<?php

include_once dirname(__FILE__).'/../db.php';
include_once dirname(__FILE__).'/../Player/Player.php';

class Role {
	//the identifier of this player role
	public $roleKey;
	//if multiple player can have this role, so this is 
	//the index of all player with this role
	public $index;
	
	public __construct($roleKey, $index) {
		$this->roleKey = $roleKey;
		$this->index = $index;
	}
	
	public static function getAllRolesOfPlayer($player) {
		$list = array();
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/loadRoleList.sql',
			array(
				"game" => $player->game,
				"user" => $player->user
			)
		);
		$set = $result->getResult();
		while ($entry = $set->getEntry()) {
			$list[] = new Role($entry["RoleKey"], intval($entry["RoleIndex"]));
		}
		$result->free();
		return $list;
	}
	
	public static function createRole($player, $roleKey) {
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/addRole.sql',
			array(
				"game" => $player->game,
				"user" => $player->user,
				"role" => $roleKey
			)
		);
		$result->getResult()->free(); //select index
		$result->getResult()->free(); //insert
		$entry = $result->getResult()->$getEntry();
		$result->free();
		return new Role($roleKey, intval($entry["RoleIndex"]));
	}
	
	public static function removeRole($player, $roleKey) {
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/removeRole.sql',
			array(
				"game" => $player->game,
				"user" => $player->user,
				"role" => $roleKey
			)
		);
		$result->executeAll();
	}
}