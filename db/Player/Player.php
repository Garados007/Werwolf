<?php

include_once dirname(__FILE__).'/../db.php';
include_once dirname(__FILE__).'/../Role/Role.php';
include_once dirname(__FILE__).'/../JsonExport/JsonExport.php';

class Player extends JsonExport {
	//the id of this player object
	public $id;
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
	//a bunch of variables used for the scripts
	private $vars;

	private static $cache = array();
	private function __construct(){}
	
	public static function create($id) {
		if (isset(self::$cache[$id]))
			return self::$cache[$id];
		$cur = new Player();
		
		$cur->jsonNames = array('id', 'game', 'user', 'alive', 
			'extraWolfLive', 'roles', 'vars');
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/loadPlayer.sql',
			array(
				"id" => $id
			)
		);
		if ($entry = $result->getResult()->getEntry()) {
			$cur->id = intval($entry["Id"]);
			$cur->game = intval($entry["Game"]);
			$cur->user = intval($entry["User"]);
			$cur->alive = boolval($entry["Alive"]);
			$cur->extraWolfLive = boolval($entry["ExtraWolfLive"]);
			$cur->vars = $entry["Vars"];
			$result->free();
			$cur->roles = Role::getAllRolesOfPlayer($cur);
		}
		else {
			$result->free();
			$cur = null;
		}

		return self::$cache[$id] = $cur;
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
		echo DB::getError();
		if ($set = $result->getResult()) $set->free(); //insert
		if ($entry = $result->getResult()->getEntry()) { //select id
			$result->flush();
			$player = self::create($entry["Id"]);
			foreach ($roleKeys as $key)
				$player->roles[] = Role::createRole($player, $key);
			return $player;
		}
		else $result->flush();
		$result->free();
	}

	public function kill($byWolf) {
		if ($byWolf && $this->extraWolfLive)
			$this->extraWolfLive = false;
		else
			$this->alive = $this->extraWolfLive = false;
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/killPlayer.sql',
			array(
				"id" => $this->id,
				"alive" => $this->alive,
				"wolf" => $this->extraWolfLive
			)
		);
		$result->free();
	}
		
	public function getRole($key) {
		for ($i = 0; $i<count($this->roles); $i++)
			if ($this->roles[$i]->roleKey == $key)
				return $this->roles[$i];
		return null;
	}
	
	public function hasRole($key) {
		for ($i = 0; $i<count($this->roles); $i++)
			if ($this->roles[$i]->roleKey == $key)
				return true;
		return false;
	}
	
	public function addRole($key) {
		$role = $this->getRole($key);
		if ($role == null)
			$role = Role::createRole($this, $key);
		return $role;
	}
	
	public function removeRole($key) {
		for ($i = 0; $i<count($this->roles); $i++)
			if ($this->roles[$i]->roleKey == $key) {
				unset($this->roles[$i]);
			}
		Role::removeRole($this, $key);
	}

	public function getVar($key) {
		if (!isset($this->vars[$key])) return null;
		return $this->vars[$key];
	}

	public function getAllVars() {
		return $this->vars;
	}

	public function setVar($key, $value = null) {
		if (!is_string($key)) throw new Exception("format exception");
		if ($value === null)
			unset($this->vars[$key]);
		else $this->vars[$key] = $value;

		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/setVars.sql',
			array(
				"id" => $this->id,
				"vars" => count($this->vars) == 0 ? null :
					json_encode($this->vars)
			)
		)->executeAll();
	}

	public function setAllVars($value = null) {
		if ($value === null)
			$this->vars = array();
		else $this->vars = $value;

		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/setVars.sql',
			array(
				"id" => $this->id,
				"vars" => count($this->vars) == 0 ? null :
					json_encode($this->vars)
			)
		)->executeAll();
	}
	
}