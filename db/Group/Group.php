<?php

include_once dirname(__FILE__).'/../db.php';
include_once dirname(__FILE__).'/../GameGroup/GameGroup.php';
include_once dirname(__FILE__).'/../JsonExport/JsonExport.php';

class Group extends JsonExport {
	//the id of this group
	public $id;
	//the name of this group
	public $name;
	//the creation time of this group
	public $created;
	//the time when the group played the last game (min. creation time)
	public $lastTime;
	//the creator id of this group
	public $creator;
	//the leader id of this group
	public $leader;
	//the current game of this group
	public $currentGame;
	//the key which is needed for enter this group
	public $enterKey;
	
	private static $cache = array();

	private function __construct() {}

	private static function createInternal($id) {
		$cur = new Group();

		$cur->jsonNames = array(
			'id', 'name', 'created', 'lastTime', 'creator',
			'leader', 'currentGame', 'enterKey'
		);
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/loadGroup.sql',
			array(
				"id" => $id
			)
		);
		if ($entry = $result->getResult()->getEntry()) {
			$cur->id = intval($entry["Id"]);
			$cur->name = $entry["Name"];
			$cur->created = intval($entry["Created"]);
			$cur->lastTime = intval($entry["LastGame"]);
			$cur->creator = intval($entry["Creator"]);
			$cur->leader = intval($entry["Leader"]);
			$cur->currentGame = $entry["CurrentGame"] === null ?
				null : intval($entry["CurrentGame"]);
			$cur->enterKey = $entry["EnterKey"];
		}
		else $cur = null;
		$result->flush();
		return $cur;
	}

	public static function create($id) {
		if (isset(self::$cache[$id]))
			return self::$cache[$id];

		$cur = self::createInternal($id);

		if ($cur !== null && $cur->currentGame !== null)
			$cur->currentGame = GameGroup::create($cur->currentGame);

		return self::$cache[$id] = $cur;
	}

	public static function forceValidation($id) {
		if (!isset(self::$cache[$id])) return;
		$cache = self::$cache[$id];
		$cur = self::createInternal($id);

		if ($cur === null) {
			self::$cache[$id] = null;
			$cache->id = null; //invalidate cached entry
			return;
		}

		foreach ($cur->jsonNames as $name)
			$cache->$name = $cur->$name;

	}
	
	public static function getIdFromKey($key) {
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/existsKey.sql',
			array(
				"key" => DB::escape(strtoupper($key))
			)
		);
		$set = $result->getResult();
		if ($set && $entry = $set->getEntry()) return intval($entry['Id']);
		else return null;
	}
	
	private static function createKey() {
		$c = '0123456789ABCDEFGHJKLMNPQRSTUWXYZ';
		$l = strlen($c);
		$s;
		do {
			$s = '';
			for ($i = 0; $i < 12; $i++) {
				$s .= $c[rand(0, $l - 1)];
			}
		}
		while (self::getIdFromKey($s) !== null);
		return $s;
	}
	
	public static function createGroup($name, $user) {
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/addGroup.sql',
			array(
				"name" => DB::escape($name),
				"time" => time(),
				"user" => $user,
				"key" => self::createKey()
			)
		);
		echo DB::getError();
		$result->freeResult();
		echo DB::getError();
		$entry = $result->getResult();
		$entry = $entry->getEntry();
		$result->free();
		return self::create($entry["Id"]);
	}
	
	public function setCurrentGame(GameGroup $game = null) {
		$id = $game === null || $game->finished !== null ? null :
			$game->id;
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/setCurrentGame.sql',
			array(
				"oldgame" => $this->currentGame === null ?
					null : $this->currentGame->id,
				"game" => $id,
				"time" => $this->lastTime = time(),
				"id" => $this->id
			)
		);
		$this->currentGame = $game;
		$result->free();
	}

	public function setLeader($leader) {
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/setLeader.sql',
			array(
				"leader" => $this->leader = $leader,
				"id" => $this->id
			)
		);
		$result->free();
	}
}