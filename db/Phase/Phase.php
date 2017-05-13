<?php

include_once dirname(__FILE__).'/../db.php';
include_once dirname(__FILE__).'/../JsonExport/JsonExport.php';

class Phase extends JsonExport {
	//the current phase
	public $current; 
	//the current Level
	public $currentLevel;
	//the next phase
	public $next;
	//the next level
	public $nextLevel;
	
	public function __construct($id, $level) {
		$this->jsonNames = array('current', 'currentLevel', 'next', 'nextLevel');
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/loadPhase.sql',
			array(
				"id" => $id,
				"level" => $level
			)
		);
		echo DB::getError();
		if ($entry = $result->getResult()->getEntry()) {
			$this->current = $entry["Phase"];
			$this->currentLevel = $entry["PhaseLevel"];
			$this->next = $entry["NextPhase"];
			$this->nextLevel = $entry["NextPhaseLevel"];
		}
		$result->flush();
	}
}