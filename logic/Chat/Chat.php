<?php

include_once dirname(__FILE__).'/../../db/ChatEntry/ChatEntry.php';
include_once dirname(__FILE__).'/../../db/ChatMode/ChatMode.php';
include_once dirname(__FILE__).'/../../db/ChatRoom/ChatRoom.php';
include_once dirname(__FILE__).'/../../db/Player/Player.php';
include_once dirname(__FILE__).'/../../db/Role/Role.php';
include_once dirname(__FILE__).'/../Game/Game.php';

class Chat {
	private static $modeBackUp = array(); //backup for fast access
	
	public static function GetChatMode($chatmode, $role) {
		if (!is_string($role)) $role = $role->roleKey;
		if (isset(self::$modeBackUp[$chatmode]) && isset(self::$modeBackUp[$chatmode][$role]))
			return self::$modeBackUp[$chatmode][$role];
		if (!isset(self::$modeBackUp[$chatmode]))
			self::$modeBackUp[$chatmode] = array();
		return self::$modeBackUp[$chatmode][$role] = new ChatMode($chatmode, $role);
	}
		
	private static $chatRoomIdBackUp = array(); //backup for chat room ids

	public static function GetChatRoomId($game, $mode) {
		if (!is_numeric($game)) $game = $game->id;
		if (isset(self::$chatRoomIdBackUp[$game]) &&
			isset(self::$chatRoomIdBackUp[$game][$mode]))
				return self::$chatRoomIdBackUp[$game][$mode];
		if (!isset(self::$chatRoomIdBackUp[$game]))
			self::$chatRoomIdBackUp[$game] = array();
		return self::$chatRoomIdBackUp[$game][$mode] =
			ChatRoom::getChatRoomId($game, $mode);
	}
		
	public static function GetAccessibleChatRooms($player) {
		$chatKeys = ChatMode::getChatKeys();
		$list = array();
		foreach ($player->roles as $role) {
			foreach ($chatKeys as $key) {
				$mode = self::GetChatMode($key, $role);
				if ($mode->enableRead) {
					$id = self::GetChatRoomId($player->game, $key);
					if (!isset($list[$id])) $list[$id] = $mode;
					elseif (!$list[$id]->enableWrite && $mode->enableWrite)
						$list[$id] = mode;
				}
			}
		}
		return $list;
	}
	
	private static $roomBackUp = array(); //backup for rooms
	
	public static function GetChatRoom($id) {
		if (!is_numeric($id)) return $id;
		if (isset(self::$roomBackUp[$id])) return self::$roomBackUp[$id];
		return self::$roomBackUp[$id] = new ChatRoom($id);
	}
	
	public static function GetPlayerInRoom($room) {
		if (is_numeric($room)) $room = self::GetChatRoom($room);
		$visibles = array();
		foreach (ChatMode::getRoleKeys() as $role) {
			$mode = self::GetChatMode($room->chatMode, $role);
			if ($mode->visible) $visibles[] = $role;
		}
		$game = Game::GetGame($room->game);
		if (!$game) return;
		$users = Game::GetAllUserFromGroup($game->mainGroupId);
		$list = array();
		foreach ($users as $user) {
			$player = Game::getPlayer($game, $user);
			$visible = false;
			foreach ($player->roles as $role) 
				$visible |= in_array($role->roleKey, $visibles);
			if ($visible) $list[] = $player;
		}
		return $list;
	}
}