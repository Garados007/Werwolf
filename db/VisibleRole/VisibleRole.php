<?php

include_once dirname(__FILE__).'/../db.php';
include_once dirname(__FILE__).'/../JsonExport/JsonExport.php';
include_once dirname(__FILE__).'/../Player/Player.php';
include_once dirname(__FILE__).'/../Role/Role.php';

class VisibleRole extends JsonExport {
	//the player who sees this role
	public $player;
	//the target who owns this role
	public $target;
	//the key of this role
	public $role;
	
	public function __construct(Player $player, Player $target, $role) {
		$this->jsonNames = array('player', 'target', 'role');
		$this->player = $player;
		$this->target = $target;
		$this->role = $role;
	}
	
	public static function loadVisibleRoles(Player $currentPlayer, Player $targetPlayer) {
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
				$currentPlayer,
				$targetPlayer,
				strval($entry["RoleKey"])
			);  
		}
		$result->free();
		return $list;
	}
	
	public static function addRoles(Player $currentPlayer, Player $targetPlayer, array $keys) {
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/addVisibleRole.sql',
			array(
				"player" => $currentPlayer->id,
				"target" => $targetPlayer->id,
				"roles" => $keys
			)
		);
		$result->free();
		$list = array();
		foreach ($keys as $k)
			$list[] = new VisibleRole($currentPlayer, $targetPlayer, $k);
		return $list;
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
		
	public static function filterRoles(Player $currentPlayer, Player $player) {
		$visible = self::loadVisibleRoles($currentPlayer, $player);
		$keys = array();
		for ($i = 0; $i<count($visible); ++$i)
			$keys[] = $visible[$i]->role;
		$left = array();
		for ($i = 0; $i<count($player->roles); ++$i)
			if (in_array($player->roles[$i]->roleKey, $keys))
				$left[] = $player->roles[$i];
		return $left;
	}
}
