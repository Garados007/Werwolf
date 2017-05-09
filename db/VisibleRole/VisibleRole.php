<?php

include_once dirname(__FILE__).'/../db.php';
include_once dirname(__FILE__).'/../JsonExport/JsonExport.php';
include_once dirname(__FILE__).'/../Player/Player.php';
include_once dirname(__FILE__).'/../Role/Role.php';

class VisibleRole extends JsonExport {
	//the game idate
	public $game;
	//the player id who sees this role
	public $mainUser;
	//the target id who owns this role
	public $target;
	//the key of this role
	public $role;
	
	public function __construct($game, $mainUser, $target, $role) {
		$this->jsonNames = array('game', 'mainUser', 'target', 'role');
		$this->game = $game;
		$this->mainUser = $mainUser;
		$this->target = $target;
		$this->role = $role;
	}
	
	public static function loadVisibleRoles($currentPlayer, $targetPlayer) {
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/loadVisibleRoles.sql',
			array(
				"game" => $currentPlayer->game,
				"main" => $currentPlayer->user,
				"target" => $targetPlayer->user
			)
		);
		$row = $result->getResult();
		$list = array();
		while ($entry = $row->getEntry()) {
			$list[] = new VisibleRole(
				intval($entry["Game"]),
				intval($entry["MainUser"]),
				intval($entry["TargetUser"]),
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
				"game" => $currentPlayer->game,
				"main" => $currentPlayer->user,
				"target" => $targetPlayer->user,
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
	
	private static $defaultVisibility = null;
	public static function addDefaultVisibility($currentPlayer, $targetPlayer) {
		if (self::$defaultVisibility !=  null)
			$default = self::$defaultVisibility;
		else $default = self::$defaultVisibility = 
			json_decode(file_get_contents(
				dirname(__FILE__).'/defaultVisibility.json'), true);
		$visible = array(); //all roles which currentPlayer can see
		for ($i = 0; $i<count($currentPlayer->roles); ++$i)
			for ($r = 0; $r<count($default[$currentPlayer->roles[$i]->roleKey]); ++$r)
				if (!in_array($default[$currentPlayer->roles[$i]->roleKey][$r], $visible))
					$visible[] = $default[$currentPlayer->roles[$i]->roleKey][$r];
		$roles = array(); //all visible roles of targetPlayer
		for ($i = 0; $i<count($targetPlayer->roles); ++$i)
			if (in_array($targetPlayer->roles[$i]->roleKey, $visible))
				$roles[] = $targetPlayer->roles[$i]->roleKey;
		self::addRoles($currentPlayer, $targetPlayer, $roles);
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
