<?php

include_once dirname(__FILE__).'/../db.php';

class ChatMode {
	//the chat text channel
	public $chatmode;
	//the role permission
	public $role;
	//enable to write in chat
	public $enableWrite;
	//enable to read and access this chat
	public $enableRead;
	//visible to other subcribers in chat
	public $visible;
	
	public function __construct($chatmode, $role) {
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/loadChatMode.sql',
			array(
				"chat" => $chatmode,
				"role" => $role
			)
		);
		if ($entry = $result->getResult()->getEntry()) {
			$this->chatmode = $entry["ChatMode"];
			$this->role = $entry["SupportedRoleKey"];
			$this->enableWrite = boolval($entry["EnableWrite"]);
			$this->enableRead = true;
			$this->visible = boolval($entry["Visible"]);
		}
		else {
			$this->chatmode = $chatmode;
			$this->role = $role;
			$this->enableWrite = false;
			$this->enableRead = false;
			$this->visible = false;
		}
		$result->flush();
	}
	
	private static $chatKeys = null;
	
	public static function getChatKeys() {
		if (self::$chatKeys === null) {
			self::$chatKeys = array();
			$result = DB::executeFormatFile(
				dirname(__FILE__).'/sql/loadChatKeys.sql',
				array()
			);
			$set = $result->getResult();
			while ($entry = $set->getEntry()) {
				self::$chatKeys[] = $entry["ChatMode"];
			}
			$result->free();
		}
		return self::$chatKeys;
	}
	
	private static $roleKeys = null;
	
	public static function getRoleKeys() {
		if (self::$roleKeys === null) {
			self::$roleKeys = array();
			$result = DB::executeFormatFile(
				dirname(__FILE__).'/sql/loadRoleKeys.sql',
				array()
			);
			$set = $result->getResult();
			while ($entry = $set->getEntry()) {
				self::$roleKeys[] = $entry["RoleKey"];
			}
			$result->free();
		}
		return self::$roleKeys;
	}
	
	public static getAllModesFromChat($chat) {
		$result = array();
		foreach (self::getRoleKeys() as $role) {
			$result[$role] = new ChatMode($chat, $role);
		}
		return $result;
	}
}
