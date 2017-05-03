<?php

include_once dirname(__FILE__).'/../../db/Group/Group.php';
include_once dirname(__FILE__).'/../../db/GameGroup/GameGroup.php';
include_once dirname(__FILE__).'/../../db/User/User.php';
include_once dirname(__FILE__).'/../../db/Player/Player.php';
include_once dirname(__FILE__).'/../../db/ChatRoom/ChatRoom.php';
include_once dirname(__FILE__).'/../../db/ChatMode/ChatMode.php';
include_once dirname(__FILE__).'/../../db/ChatEntry/ChatEntry.php';
include_once dirname(__FILE__).'/../Chat/Chat.php';

class Game {
	private static $groupBackup = array();
	
	public static function GetGroup($group) {
		if (!is_numeric($group)) return $group;
		if (isset(self::$groupBackup[$group])) return self::$groupBackup[$group];
		return self::$groupBackup[$group] = new Group($group);
	}
	
	public static function CreateGroup($name, $user) {
		$group = Group::createGroup($name, $user);
		self::$groupBackup[$group->id] = $group;
		return $group;
	}
	
	private static $gameBackup = array();
	
	private static $creationRolesTable = null;
	
	//roles: easy array where every role is listet
	public static function CreateGame($group, $roles) {
		$group = self::GetGroup($group);
		//create Game object
		$game = GameGroup::createNew($group->id);
		self::$gameBackup[$game->id] = $game;
		//attach game to group
		$group->setCurrentGame($game);
		//create player and assign roles
		$playerList = self::GetAllUserFromGroup($group);
		unset($playerList[$group->leader]); //this is our storyteller
		shuffle($playerList);
		if (self::$creationRolesTable === null)
			self::$creationRolesTable = json_decode(file_get_contents(
				dirname(__FILE__).'/roleKeys.json'), true);
		for ($i = -1; $i<count($playerList); $i++) {
			$user = $i == -1 ? $group->leader : $playerList[$i];
			$role = $i < 0 ? "storytel" :
				(count($roles) > $i ? $roles[$i] : "villager");
			$player = Player::createNewPlayer($game->id, $user,
				self::$creationRolesTable[$role]);
			if (!isset(self::$playerBackup[$game->id]))
				self::$playerBackup[$game->id] = array();
			self::$playerBackup[$game->id][$user] = $player;
		}
		//create chat rooms
		foreach (ChatMode::getChatKeys() as $key)
			ChatRoom::createChatRoom($game->id, $key);
		//finish
		return $game;
	}
	
	public static function GetGame($game) {
		if (!is_numeric($game)) return $game;
		if (isset(self::$gameBackup[$game])) return self::$gameBackup[$game];
		$game = new GameGroup($game);
		return self::$gameBackup[$game->id] = $game;
	}
	
	public static function GetUserGroups($user) {
		if (is_array($user)) return $user;
		$list = array();
		foreach (User::loadAllGroupsByUser($user) as $group)
			$list[] = $group->group;
		return $list;
	}
	
	public static function GetAllUserFromGroup($group) {
		if (is_array($group)) return $group;
		$list = array();
		$users = User::loadAllUserByGroup(
			is_numeric($group) ? $group : $group->id);
		foreach ($users as $user)
			$list[] = $user->user;
		return $list;
	}
	
	public static function AddUserToGroup($user, $group) {
		return User::createUser($group, $user);
	}
	
	private static $playerBackup = array();
	
	public static function getPlayer($game, $user) {
		if (is_numeric($game)) $game = self::GetGame($game);
		if (isset(self::$playerBackup[$game->id]) &&
			isset(self::$playerBackup[$game->id][$user]))
			return self::$playerBackup[$game->id][$user];
		if (!isset(self::$playerBackup[$game->id]))
			self::$playerBackup[$game->id] = array();
		return self::$playerBackup[$game->id][$user] = new Player($game->id, $user);
	}
	
	private static $openChatRooms = null;
	
	public static function NextRound($game) {
		if (is_numeric($game)) $game = self::GetGame($game);
		$game->nextPhase();
		if (self::$openChatRooms === null)
			self::$openChatRooms = json_decode(
				file_get_contents(dirname(__FILE__).'/openChatRooms.json'), true);
		$story = null;
		foreach (ChatMode::getChatKeys() as $key) {
			$chat = Chat::GetChatRoom(Chat::GetChatRoomId($game, $key));
			Chat::DeleteVoting($chat->id);
			$chat->changeOpenedState(in_array($chat->chatMode,
				self::$openChatRooms[$game->phase->current]));
			if ($key == 'story') $story = $chat;
		}
		ChatEntry::addEntry($story->id, 0, 
			'[{"tid":10}]');
		return $game;
	}
	
	public static function CheckIfFinished($game) {
		if (is_numeric($game)) $game = self::GetGame($game);
		if ($game->finished !== null) return true;
		$wolfLeft = false;
		$villLeft = false;
		$pairLeft = false;
		$othpLeft = false;
		foreach (self::GetAllUserFromGroup($game->mainGroupId) as $user) {
			$player = self::getPlayer($game, $user);
			if (!$player->alive) continue;
			$pair = false;
			foreach ($player->roles as $role)
				switch ($role->roleKey) {
					case "villager": $villLeft = true; break;
					case "wolf": $wolfLeft = true; break;
					case "pair": $pairLeft = true; $pair = true; break;
				}
			if (!$pair) $othpLeft = true;
		}
		if (!$wolfLeft || !$villLeft || !$othpLeft) {
			$game->finish();
			return true;
		}
		else return false;
	}
}
