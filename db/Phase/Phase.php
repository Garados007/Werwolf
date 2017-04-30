<?php

include_once dirname(__FILE__).'/../db.php';
include_once dirname(__FILE__).'/../JsonExport/JsonExport.php';

class Phase extends JsonExport {
	//the current phase
	public $current; 
	//the next phase
	public $next;
	
	public function __construct($id) {
		$this->jsonNames = array('current', 'next');
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/loadPhase.sql',
			array(
				"id" => $id
			)
		);
		if ($entry = $result->getResult()->getEntry()) {
			$this->current = $entry["Phase"];
			$this->next = $entry["NextPhase"];
		}
		$result->flush();
	}
}