<?php

include_once dirname(__FILE__).'/../db.php';
include_once dirname(__FILE__).'/../JsonExport/JsonExport.php';
include_once dirname(__FILE__).'/../Player/Player.php';
include_once dirname(__FILE__).'/../Role/Role.php';

class VisibleRole extends JsonExport {
	//the player id who sees this role
	public $player;
	//the target id who owns this role
	public $target;
	//the key of this role
	public $role;
	
	public function __construct($player, $target, $role) {
		$this->jsonNames = array('player', 'target', 'role');
		$this->player = $player;
		$this->target = $target;
		$this->role = $role;
	}
	
	public static function loadVisibleRoles($currentPlayer, $targetPlayer) {
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/loadVisibleRoles.sql',
			array(
				"player" => $currentPlayer->id,
				"target" => $targetPlayer->id
			)
		);
		$row = $result->getResult();
		$list = array();
		while ($entry = $row->getEntry()) {
			$list[] = new VisibleRole(
				intval($entry["Player"]),
				intval($entry["Target"]),
				strval($entry["RoleKey"])
			);  
		}
		$result->free();
		return $list;
	}
	
	public static function addRoles($currentPlayer, $targetPlayer, $keys) {
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/addVisibleRole.sql',
			array(
				"player" => $currentPlayer->id,
				"target" => $targetPlayer->id,
				"roles" => $keys
			)
		);
		$result->free();
	}
	
	public static function deleteAllRoles($gameId) {
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/deleteAllVisibleRoles.sql',
			array(
				"game" => $gameId
			)
		);
		$result->free();
	}
		
	public static function filterRoles($currentPlayer, $player) {
		$visible = self::loadVisibleRoles($currentPlayer, $player);
		$keys = array();
		for ($i = 0; $i<count($visible); ++$i)
			$keys[] = $visible[$i]->role;
		$left = array();
		for ($i = 0; $i<count($player->roles); ++$i)
			if (in_array($player->roles[$i]->roleKey, $keys))
				$left[] = $player->roles[$i];
		$player->roles = $left;
	}
}
