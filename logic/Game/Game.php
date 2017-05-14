<?php

include_once dirname(__FILE__).'/../../db/Group/Group.php';
include_once dirname(__FILE__).'/../../db/GameGroup/GameGroup.php';
include_once dirname(__FILE__).'/../../db/User/User.php';
include_once dirname(__FILE__).'/../../db/Player/Player.php';
include_once dirname(__FILE__).'/../../db/ChatRoom/ChatRoom.php';
include_once dirname(__FILE__).'/../../db/ChatMode/ChatMode.php';
include_once dirname(__FILE__).'/../../db/ChatEntry/ChatEntry.php';
include_once dirname(__FILE__).'/../../db/VisibleRole/VisibleRole.php';
include_once dirname(__FILE__).'/../Chat/Chat.php';

class Game {
	private static $groupBackup = array();
	
	public static function GetGroup($group) {
		if (!is_numeric($group)) return $group;
		if (isset(self::$groupBackup[$group])) return self::$groupBackup[$group];
		return self::$groupBackup[$group] = new Group($group);
	}
	
	public static function GetGroupByKey($key) {
		$id = Group::getIdFromKey($key);
		if ($id == null) return null;
		else return self::GetGroup($id);
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
		if(($key = array_search($group->leader, $playerList)) !== false)
			unset($playerList[$key]); //this is our storyteller
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
		//setup visibility
		$list = array();
		for ($i = -1; $i<count($playerList); $i++) {
			$user = $i == -1 ? $group->leader : $playerList[$i];
			$list[] = self::getPlayer($game->id, $user);
		}
		foreach ($list as $player1)
			foreach ($list as $player2)
				VisibleRole::addDefaultVisibility($player1, $player2);
		//create chat rooms
		self::loadOpenChatRooms();
		foreach (ChatMode::getChatKeys() as $key) {
			$chat = ChatRoom::createChatRoom($game->id, $key);
			$chat->changeOpenedState(in_array($chat->chatMode,
				self::$openChatRooms[$game->phase->current]));
			$chat->changeEnableVotingState(in_array($chat->chatMode,
				self::$enableVotings[$game->phase->current]));
			if ($key == "story")
				ChatEntry::addEntry($chat->id, 0,
					'{"tid":22,"var":{}}');
		}
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
	
	public static function killPlayer($player, $byWolf) {
		$player->kill($byWolf);
		if (!$player->alive) {
			$game = self::GetGame($player->game);
			$user = self::GetAllUserFromGroup($game->mainGroupId);
			foreach ($user as $other) {
				$other = self::getPlayer($player->game, $other);
				$keys = array();
				for ($i = 0; $i<count($other->roles); ++$i)
					$keys[] = $other->roles[$i]->roleKey;
				VisibleRole::addRoles($player, $other, $keys);
			}
			if ($player->hasRole('pair')) {
				$story = Chat::GetChatRoomId($game, 'story');
				foreach ($user as $other) {
					$other = self::getPlayer($player->game, $other);
					if ($other->hasRole('pair') && $other->alive) {
						self::killPlayer($other, false);
						ChatEntry::addEntry($story, 0,
							'{"tid":17,"var":{"p1":'.
							$other->user.',"p2":'.
							$player->user.'}}');
					}
				}
			}
		}
	}
	
	private static $openChatRooms = null;
	private static $enableVotings = null;
	private static function loadOpenChatRooms() {
		if (self::$openChatRooms === null)
			self::$openChatRooms = json_decode(
				file_get_contents(dirname(__FILE__).'/openChatRooms.json'), true);
		if (self::$enableVotings=== null)
			self::$enableVotings = json_decode(
				file_get_contents(dirname(__FILE__).'/enableVotings.json'), true);
	}
	
	public static function NextRound($game) {
		if (is_numeric($game)) $game = self::GetGame($game);
		$game->nextPhase();
		self::loadOpenChatRooms();
		$story = null;
		foreach (ChatMode::getChatKeys() as $key) {
			$chat = Chat::GetChatRoom(Chat::GetChatRoomId($game, $key));
			Chat::DeleteVoting($chat->id);
			$chat->changeOpenedState(in_array($chat->chatMode,
				self::$openChatRooms[$game->phase->current]));
			$chat->changeEnableVotingState(in_array($chat->chatMode,
				self::$enableVotings[$game->phase->current]));
			if ($key == 'story') $story = $chat;
		}
		ChatEntry::addEntry($story->id, 0, 
			'{"tid":10,"var":{}}');
		if (self::CheckIfFinished($game))
			ChatEntry::addEntry($story->id, 0,
				'{"tid":11,"var":{}}');
		else switch ($game->phase->current) {
			case "armorsel": 
				ChatEntry::addEntry($story->id, 0,
					'{"tid":20,"var":{}}');
				break;
			case "awakenin": 
				ChatEntry::addEntry($story->id, 0,
					'{"tid":21,"var":{}}');
				break;
			case "mainstor":
				ChatEntry::addEntry($story->id, 0,
					'{"tid":22,"var":{}}');
				break;
			case "majorsel": 
				ChatEntry::addEntry($story->id, 0,
					'{"tid":23,"var":{}}');
				break;
			case "sleepnow": 
				ChatEntry::addEntry($story->id, 0,
					'{"tid":24,"var":{}}');
				break;
			case "villkill": 
				ChatEntry::addEntry($story->id, 0,
					'{"tid":25,"var":{}}');
				break;
			case "wolfkill": 
				ChatEntry::addEntry($story->id, 0,
					'{"tid":26,"var":{}}');
				break;
			case "oraclesl":
				ChatEntry::addEntry($story->id, 0,
					'{"tid":27,"var":{}}');
				break;
			default: var_dump($game); break;
		}
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
			$master = false;
			$villager = 0;
			foreach ($player->roles as $role)
				switch ($role->roleKey) {
					case "villager": $villager += 1; break;
					case "wolf": $wolfLeft = true; $villager = 2; break;
					case "pair": $pairLeft = true; $pair = true; break;
					case "storytel": $master = true; break;
				}
			if ($villager == 1) $villLeft = true;
			if (!$pair && !$master) $othpLeft = true;
		}
		if (!$wolfLeft || !$villLeft || !$othpLeft) {
			$game->finish();
			$story = Chat::GetChatRoomId($game, 'story');
			if ($pairLeft && !$othpLeft)
				ChatEntry::addEntry($story, 0,
					'{"tid":30,"var":{}}');
			elseif ($wolfLeft)
				ChatEntry::addEntry($story, 0,
					'{"tid":31,"var":{}}');
			elseif ($villLeft)
				ChatEntry::addEntry($story, 0,
					'{"tid":32,"var":{}}');
			return true;
		}
		else return false;
	}
}
