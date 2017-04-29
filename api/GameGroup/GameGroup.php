<?php

include_once dirname(__FILE__).'/../../db/db.php';
include_once dirname(__FILE__).'/../Phase/Phase.php';

class GameGroup { 
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
	
	public function __construct($id) {
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/loadGroup.sql',
			array(
				"id" => $id
			)
		);
		if ($entry = $result->getResult()->getEntry()) {
			$this->id = $entry["Id"];
			$this->mainGroupId = $entry["MainGroup"];
			$this->started = intval($entry["Started"]);
			$this->finished = $entry["Finished"];
			$this->phase = new Phase($entry["CurrentPhase"]);
		}
		$result->flush();
	}
	
	public static function createNew($mainGroupId) {
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/createGroup.sql',
			array(
				"mainGroup" => $mainGroupId
			)
		);
		$result->getResult()->free(); //insert
		if ($entry = $result->getResult()->getEntry()) { //select id
			$result->flush();
			return new GameGroup($entry["Id"]);
		}
		else $result->flush();
	}
	
	public function nextPhase() {
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/nextPhase.sql',
			array(
				"id" => $this->id,
				"next" => $this->phase->next
			)
		)->executeAll();
		$this->phase = new Phase($this->phase-next);
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
}