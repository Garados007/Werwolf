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
	private $vars;
	//the winning roles
	public $winningRoles;
	
	public function __construct($id) {
		$this->jsonNames = array('id', 'mainGroupId', 'started',
			'finished', 'phase', 'day', 'ruleset', 'vars', 'winningRoles');
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/loadGroup.sql',
			array(
				"id" => $id
			)
		);
		echo DB::getError();
		if ($entry = $result->getResult()->getEntry()) {
			$this->id = $entry["Id"];
			$this->mainGroupId = $entry["MainGroup"];
			$this->started = intval($entry["Started"]);
			$this->finished = $entry["Finished"];
			$this->phase = $entry["CurrentPhase"];
			$this->day = $entry["CurrentDay"];
			$this->ruleset = $entry["Ruleset"];
			if ($entry["Vars"] !== null)
				$this->vars = json_decode($entry["Vars"], true);
			else $this->vars = array();
		}
		$result->flush();

		if ($this->finished !== null) {
			$this->winningRoles = array();
			$result = DB::executeFormatFile(
				__DIR__ . '/sql/getWinningGame.sql',
				array(
					"game" => $id
				)
			);
			echo DB::getError();
			$set = $result->getResult();
			while ($entry = $set->getEntry()) {
				$this->winningRoles[] = $entry["Role"];
			}
		}
		else $this->winningRoles = null;
	}
	
	public static function createNew($mainGroupId, $phase, $rules, $vars = null) {
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/createGroup.sql',
			array(
				"mainGroup" => $mainGroupId,
				"phase" => $phase,
				"rules" => $rules,
				"vars" => $vars
			)
		);
		echo DB::getError();
		if ($set = $result->getResult()) $set->free(); //insert
		if ($entry = $result->getResult()->getEntry()) { //select id
			$result->flush();
			return new GameGroup($entry["Id"]);
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