<?php

include_once dirname(__FILE__).'/../logic/Game/Game.php';

class Api {
	public $params;
	
	public $result;
	
	public $error;
	
	public $errorKey;
	
	public function __construct($params) {
		$this->params = $params;
		//$this->wrapAction();
		$this->work();
	}
	
	public function exportResult() {
		if ($this->error !== null) {
			return json_encode(array(
				"success" => false,
				"error" => $this->error,
				"errorkey" => $this->errorKey
			));
		}
		else {
			return json_encode(array(
				"success" => true,
				"result" => $this->result
			));
		}
	}
	
	private function wrapAction() {
		ob_start();
		$this->work();
		$output = ob_get_contents();
		ob_end_clean();
		if ($output != '') {
			$this->error = $output;
			$this->errorKey = 'unknown output';
		}
	}
	
	private function getStr($name) {
		return strval($this->params[$name]);
	}
	
	private function getInt($name) {
		return intval($this->params[$name]);
	}
	
	private function check($names) {
		foreach ($names as $name) {
			if (!isset($this->params[$name])) {
				$this->error = "missing parameter '$$name'";
				return false;
			}
		}
		return true;
	}
	
	private function work() {
		if (!$this->check(['mode'])) return;
		switch ($this->params["mode"]) {
			case "createGroup": $this->createGroup(); break;
			case "addUserToGroup": $this->addUserToGroup(); break;
			case "getUserFromGroup": $this->getUserFromGroup(); break;
			case "getGroupFromUser": $this->getGroupFromUser(); break;
			
			
			default: $this->error = "not supported mode"; break;
		}
	}
	
	//Group functions
	
	private function createGroup() {
		if (!$this->check(['name', 'user'])) return;
		$group = Game::CreateGroup(
			$this->getStr("name"),
			$this->getInt("user")
		); 
		$user = Game::AddUserToGroup(
			$this->getInt("user"),
			$group
		);
		$this->result = array(
			"method" => 'createGroup',
			"group" => $group->exportJson(),
			"user" => $user->exportJson()
		);
	}
	
	private function addUserToGroup() {
		if (!$this->check(['user', 'group'])) return;
		$user = Game::AddUserToGroup(
			$this->getInt("user"),
			$this->getInt("group")
		);
		$this->result = array(
			"method" => 'addUserToGroup',
			"user" => $user->exportJson()
		);
	}
	
	private function getUserFromGroup() {
		if (!$this->check(['group'])) return;
		$list = Game::GetAllUserFromGroup(
			$this->getInt('group')
		);
		$this->result = array(
			"method" => 'getUserFromGroup',
			"group" => $this->getInt('group'),
			"user" => $list
		);
	}
	
	private function getGroupFromUser() {
		if (!$this->check(['user'])) return;
		$list = Game::GetUserGroups(
			$this->getInt('user')
		);
		$this->result = array(
			"method" => 'getGroupFromUser',
			"user" => $this->getInt('user'),
			"group" => $list
		);
	}
	
	
}