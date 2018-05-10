<?php

include_once dirname(__FILE__).'/../db.php';
include_once dirname(__FILE__).'/../JsonExport/JsonExport.php';

class ChatPermission extends JsonExport {
	//the current chatroom
	public $room;
	//the current role key
	public $roleKey;
	//permission to read chats from this room
	public $enable;
	//permission to write chats to this room (required read permission)
	public $write;
	//player of this role are invisible to others in this room only
	//under following conditions:
	// 1. current permission gives read but no write access
	// 2. they a no other roles with one of the following permission
	//    sets:
	//    - read, no write, visible
	//    - read, write
	public $visible;
	
	public function __construct($room, $roleKey, $enable, $write, $visible) {
		$this->jsonNames = array('room', 'roleKey', 'enable', 'write', 'visible');
		$this->room = $room;
		$this->roleKey = $roleKey;
		$this->enable = $enable;
		$this->write = $write;
		$this->visible = $visible;
	}
	
	public static function loadPermissions($chatRoomId) {
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/loadPermissions.sql',
			array(
				"room" => $chatRoomId
			)
		);
		$row = $result->getResult();
		$list = array();
		while ($entry = $row->getEntry()) {
			$list[] = new ChatPermission(
				intval($entry["room"]),
				strval($entry["RoleKey"]),
				boolval($entry["PEnable"]),
				boolval($entry["PWrite"]),
				boolval($entry["PVisible"])
			);  
		}
		$result->free();
		return $list;
	}
	
	public static function addPermissions(ChatPermission $permissions) {
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/addPermissions.sql',
			array(
				"room" => $permissions->room,
				"key" => $permissions->roleKey,
				"enable" => $permissions->enable,
				"write" => $permissions->write,
				"visible" => $permissions->visible
			)
		);
		$result->free();
	}
	
	public static function deleteAllPermissions($chatRoomId) {
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/deleteAllPermissions.sql',
			array(
				"room" => $chatRoomId
			)
		);
		$result->free();
	}
}
