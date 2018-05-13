<?php

include_once dirname(__FILE__).'/../db.php';
include_once dirname(__FILE__).'/../JsonExport/JsonExport.php';

class GameGroup extends JsonExport { 
	//the id of this group
	public $id;
	//the id of the global group of this game
	public $mainGroupId;
	//The time when the game startes
	public $started;
	//The time when the game ends or null if its running
	public $finished; 
	//the current phase
	public $phase;
	//the current day
	public $day;
	//the current ruleset
	public $ruleset;
	//the current vars;
	protected $vars;
	//the winning roles
	public $winningRoles;

	private static $cache = array();

	private function __construct() {}
	
	public static function create($id) {
		if (isset(self::$cache[$id]))
			return self::$cache[$id];
		$cur = new GameGroup();

		$cur->jsonNames = array('id', 'mainGroupId', 'started',
			'finished', 'phase', 'day', 'ruleset', 'vars', 'winningRoles');
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/loadGroup.sql',
			array(
				"id" => $id
			)
		);
		echo DB::getError();
		if ($entry = $result->getResult()->getEntry()) {
			$cur->id = intval($entry["Id"]);
			$cur->mainGroupId = intval($entry["MainGroup"]);
			$cur->started = intval($entry["Started"]);
			$cur->finished = intvaln($entry["Finished"]);
			$cur->phase = $entry["CurrentPhase"];
			$cur->day = intval($entry["CurrentDay"]);
			$cur->ruleset = $entry["RuleSet"];
			if ($entry["Vars"] !== null)
				$cur->vars = json_decode($entry["Vars"], true);
			else $cur->vars = array();
		}
		else $cur = null;
		$result->flush();

		if ($cur != null) {
			if ($cur->finished !== null) {
				$cur->winningRoles = array();
				$result = DB::executeFormatFile(
					__DIR__ . '/sql/getWinningGame.sql',
					array(
						"game" => $id
					)
				);
				echo DB::getError();
				$set = $result->getResult();
				while ($entry = $set->getEntry()) {
					$cur->winningRoles[] = $entry["Role"];
				}
			}
			else $cur->winningRoles = null;
		}
		return self::$cache[$id] = $cur;
	}
	
	public static function createNew($mainGroupId, $phase, $rules, $vars = null) {
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/createGroup.sql',
			array(
				"mainGroup" => $mainGroupId,
				"phase" => $phase,
				"rules" => $rules,
				"vars" => DB::escape(json_encode($vars))
			)
		);
		echo DB::getError();
		if ($set = $result->getResult()) $set->free(); //insert
		if ($entry = $result->getResult()->getEntry()) { //select id
			$result->flush();
			return self::create($entry["Id"]);
		}
		else $result->flush();
	}
	
	public function nextPhase($phase, $day) {
		if (!is_string($phase)) throw new Exception("format exception");
		if (!is_int($day)) throw new Exception("format exception");

		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/nextPhase.sql',
			array(
				"id" => $this->id,
				"next" => $phase,
				"day" => $day
			)
		)->executeAll();
		$this->phase = $phase;
		$this->day = $day;
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
					DB::escape(json_encode($this->vars))
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
					DB::escape(json_encode($this->vars))
			)
		)->executeAll();
	}
	
	public function finish() {
		$this->finished = time();
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/finishGame.sql',
			array(
				"id" => $this->id,
				"finished" => $this->finished
			)
		)->executeAll();
	}

	public function setWinner(array $roles) {
		$result = DB::executeFormatFile(
			__DIR__ . '/sql/setWinningGame.sql',
			array(
				"game" => $this->id,
				"roles" => $this->winningRoles = $roles
			)
		)->executeAll();
	}
}