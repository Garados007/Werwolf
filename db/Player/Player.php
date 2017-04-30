<?php

include_once dirname(__FILE__).'/../db.php';
include_once dirname(__FILE__).'/../Role/Role.php';
include_once dirname(__FILE__).'/../JsonExport/JsonExport.php';

class Player extends JsonExport {
	//the id of the current game
	public $game;
	//the id of the user
	public $user;
	//is this player alive - death player can see everything but cannot change something
	public $alive;
	//does have this player an extra live if wolfes want to kill him
	public $extraWolfLive;
	//a list of assigned roles
	public $roles;
	
	public function __construct($game, $user) {
		$this->jsonNames = array('game', 'user', 'alive', 'extraWolfLive',
			'roles');
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/loadPlayer.sql',
			array(
				"game" => $game,
				"user" => $user
			)
		);
		if ($entry = $result->getResult()->getEntry()) {
			$this->game = $entry["Game"];
			$this->user = $entry["User"];
			$this->alive = $entry["Alive"];
			$this->extraWolfLive = $entry["ExtraWolfLive"];
			$result->free();
			$this->roles = Role::getAllRolesOfPlayer($this);
		}
		else $result->free();
	}
	
	public static function createNewPlayer($game, $user, $roleKeys) {
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/createPlayer.sql',
			array(
				"game" => $game,
				"user" => $user,
				"extraLive" => in_array('grandpa', $roleKeys)
			)
		);
		$result->free();
		$player = new Player($game, $user);
		foreach ($roleKeys as $key)
			$player->roles[] = Role::createRole($player, $key);
		return $player;
	}
}