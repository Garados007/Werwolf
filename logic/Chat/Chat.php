<?php

include_once dirname(__FILE__).'/../../db/ChatEntry/ChatEntry.php';
include_once dirname(__FILE__).'/../../db/ChatMode/ChatMode.php';
include_once dirname(__FILE__).'/../../db/ChatRoom/ChatRoom.php';
include_once dirname(__FILE__).'/../../db/Player/Player.php';
include_once dirname(__FILE__).'/../../db/Role/Role.php';

class Chat {
	private static $modeBackUp = array(); //backup for fast access
	
	public static function GetChatMode($chatmode, $role) {
		if (isset(self::$modeBackUp[$chatmode]) && isset(self::$modeBackUp[$chatmode][$role]))
			return self::$modeBackUp[$chatmode][$role];
		if (!isset(self::$modeBackUp[$chatmode]))
			self::$modeBackUp[$chatmode] = array();
		return self::$modeBackUp[$chatmode][$role] = new ChatMode($chatmode, $role);
	}
	
	public static function GetAccessibleChatRooms($player) {
		
	}
}