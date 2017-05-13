<?php

include_once dirname(__FILE__).'/../db.php';
include_once dirname(__FILE__).'/../Phase/Phase.php';
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
	
	public function __construct($id) {
		$this->jsonNames = array('id', 'mainGroupId', 'started',
			'finished', 'phase');
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
			$this->phase = new Phase($entry["CurrentPhase"], 
				intval($entry["CurrentLevel"]));
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
		echo DB::getError();
		if ($set = $result->getResult()) $set->free(); //insert
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
				"next" => $this->phase->next,
				"level" => $this->phase->nextLevel
			)
		)->executeAll();
		$this->phase = new Phase($this->phase->next, $this->phase->nextLevel);
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