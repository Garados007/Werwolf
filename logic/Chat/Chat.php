<?php

include_once dirname(__FILE__).'/../../db/ChatEntry/ChatEntry.php';
include_once dirname(__FILE__).'/../../db/ChatMode/ChatMode.php';
include_once dirname(__FILE__).'/../../db/ChatRoom/ChatRoom.php';
include_once dirname(__FILE__).'/../../db/Player/Player.php';
include_once dirname(__FILE__).'/../../db/Role/Role.php';
include_once dirname(__FILE__).'/../../db/VoteSetting/VoteSetting.php';
include_once dirname(__FILE__).'/../../db/VoteEntry/VoteEntry.php';
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
	
	public static function GetLastChat($room, $since) {
		if (!is_numeric($room)) $room = $room->id;
		if ($since == 0) $since = null;
		return ChatEntry::loadAllEntrys($room, $since);
	}
	
	public static function AddChat($room, $player, $text) {
		if (!is_numeric($room)) $room = $room->id;
		if (!is_numeric($player)) $player = $player->user;
		return ChatEntry::addEntry($room, $player, $text);
	}
		
	public static function CreateVoting($room, $end) {
		if (!is_numeric($room)) $room = $room->id;
		if ($end == 0) $end = null;
		return VoteSetting::createVoteSetting($room, $end);
	}
	
	public static function EndVoting($room) {
		if (is_numeric($room)) $room = self::GetChatRoom($room);
		if ($room->voting) {
			$max = 0;
			$list = array();
			foreach (VoteEntry::getVotesBySetting($room->id) as $vote) {
				if (!isset($list[$vote->target]))
					$list[$vote->target] = 1;
				else $list[$vote->target]++;
				if ($max < $list[$vote->target])
					$max = $list[$vote->target];
			}
			$list2 = array();
			foreach ($list as $key => $value)
				if ($value == $max)
					$list2[] = $key;
			$result = null;
			if (count($list2) > 0)
				$result = $list2[rand(0, count($list)-1)];
			$room->voting->endVoting($result);
			return $result;
		}
	}
	
	public static function DeleteVoting($room) {
		if (is_numeric($room)) $room = self::GetChatRoom($room);
		if ($room->voting) {
			$room->voting->deleteVoting();
			$room->voting = null;
		}
	}
	
	public static function AddVote($room, $player, $target) {
		if (!is_numeric($room)) $room = $room->id;
		if (!is_numeric($player)) $player = $player->user;
		if (!is_numeric($target)) $taget = $target->user;
		return VoteEntry::CreateVote($room, $player, $target);
	}
	
	public static function GetVotesFromRoom($room) {
		if (!is_numeric($room)) $room = $room->id;
		return VoteEntry::getVotesBySetting($room);
	}
	
	public static function GetVoteFromPlayer($room, $player) {
		if (!is_numeric($room)) $room = $room->id;
		if (!is_numeric($player)) $player = $player-id;
		return VoteEntry::getVoteByUser($room, $player);
	}
}