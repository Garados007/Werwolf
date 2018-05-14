<?php

include_once dirname(__FILE__).'/../db.php';
include_once dirname(__FILE__).'/../Player/Player.php';
include_once dirname(__FILE__).'/../JsonExport/JsonExport.php';

class Role extends JsonExport {
	//the identifier of this player role
	public $roleKey;
	//if multiple player can have this role, so this is 
	//the index of all player with this role
	public $index;
	
	public function __construct($roleKey, $index) {
		$this->jsonNames = array('roleKey', 'index');
		$this->roleKey = $roleKey;
		$this->index = $index;
	}
	
	public static function getAllRolesOfPlayer(Player $player) {
		$list = array();
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/loadRoleList.sql',
			array(
				"player" => $player->id
			)
		);
		$set = $result->getResult();
		while ($entry = $set->getEntry()) {
			$list[] = new Role($entry["RoleKey"], intval($entry["RoleIndex"]));
		}
		$result->free();
		return $list;
	}
	
	public static function createRole(Player $player, $roleKey) {
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/addRole.sql',
			array(
				"game" => $player->game,
				"player" => $player->id,
				"role" => $roleKey
			)
		);
		if ($set = $result->getResult()) $set->free(); //select index
		if ($set = $result->getResult()) $set->free(); //insert
		$entry = $result->getResult()->getEntry();
		$result->free();
		$role = new Role($roleKey, intval($entry["RoleIndex"]));
		$player->roles[] = $role;
		return $role;
	}
	
	public static function removeRole(Player $player, $roleKey) {
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/removeRole.sql',
			array(
				"game" => $player->game,
				"player" => $player->id,
				"role" => $roleKey
			)
		);
		$result->executeAll();
	}
}