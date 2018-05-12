<?php

include_once __DIR__ . "/RoleBase.php";
include_once __DIR__ . "/RoundInfo.php";
include_once __DIR__ ."/../../db/User/User.php";
include_once __DIR__ ."/../../db/Player/Player.php";
include_once __DIR__ ."/../../db/GameGroup/GameGroup.php";
include_once __DIR__ ."/../../db/Group/Group.php";
include_once __DIR__ ."/../../db/ChatRoom/ChatRoom.php";
include_once __DIR__ ."/../../db/ChatPermission/ChatPermission.php";
include_once __DIR__ ."/../../db/VoteSetting/VoteSetting.php";

class RoleHandler {
    private static $roleBuffer = array();
    private static $configBuffer = array();
    private static $phaseBuffer = array();
    private $group;
    private $config;
    private $phases;
    private $controler = null;
    private $chats = null;

    public function __construct(GameGroup $group) {
        $this->group = $group;
        $this->config = self::loadConfig($group->ruleset);
        //construct phase buffer
        if (isset(self::$phaseBuffer[$group->ruleset]))
            $this->phases = self::$phaseBuffer[$group->ruleset];
        else {
            $this->phases = array();
            $order = $this->config->start == "night" ?
                array('night', 'day') : array('day', 'night');
            foreach ($order as $phi) {
                foreach ($this->config->$phi as $ph) {
                    $this->phases[] = substr($phi, 0, 1) . ":${ph}";
                }
            }
            self::$phaseBuffer[$group->ruleset] = $this->phases;
        }
    }

    private static function loadConfig($key) {
        if (isset(self::$configBuffer[$key]))
            return self::$configBuffer[$key];
        if (!is_file(__DIR__ . "/${key}/config.json")) 
            return self::$configBuffer[$key] = false;
        $json = json_decode(file_get_contents(__DIR__ . "/${key}/config.json"));
        return self::$configBuffer[$key] = $json;
    }

    public static function loadAllRoles($key) {
        if (isset(self::$roleBuffer[$key]))
            return true;
        $config = self::$loadConfig($key);
        if ($config === false) {
            $this->roleBuffer[$key] = array();
            return false;
        }
        $roles = array();
        foreach ($config->roles as $role) {
            if (is_file(__DIR__ . "/${key}/${role}.php")) {
                $roles[] = $role;
                include_once __DIR__ . "/${key}/${role}.php";
            }
        }
        self::$roleBuffer[$key] = $roles;
        return true;
    }

    public static function getRoles($key) {
        return isset(self::$roleBuffer[$key]) ? self::$roleBuffer[$key] : false;
    }

    private function getRunningRoles() {
        if (!self::loadAllRoles($this->group->ruleset)) return false;
        $roles = self::getRoles($this->group->ruleset);
        $player = $this->getPlayer();
        $proles = array();
        foreach ($player as $p) {
            foreach ($p->roles as $r) {
                $proles[] = $r->roleKey;
            }
        }
        return array_filter($roles, function ($role) {
            return in_array($role, $proles);
        });
    }

    public function createAllControler() {
        if ($this->controler !== null) 
            return $this->controler;
        $controler = array();
        foreach ($this->getRunningRoles() as $role) {
            $name = $this->group->ruleset . "_${role}";
            $control = new $name();
            $control->roleHandler = $this;
            $controler[$role] = $control;
        }
        return $this->coontroler = $controler;
    }

    private function getChats() {
        if ($this->chats !== null) return;
        $chats = array();
        foreach ($this->config->chats as $key) {
            $chats[] = ChatRoom::create(
                ChatRoom::getChatRoomId($this->game->id, $key));
        }
        $this->chats = $chats;
    }

    //region main control functions
    private $nextRoundActive = false;

    public function nextRound() {
        //remove cyclic call
        if ($this->nextRoundActive) return;
        $this->nextRoundActive = true;

        //get controlers
        $this->createAllControler();
        //remove permissions from chats
        $this->getChats();
        foreach ($this->chats as $chat)
            if (!in_array($chat->chatRoom, $this->config->chats_exceptions))
                ChatPermission::deleteAllPermissions($chat->id);

        //finish votings and delete it
        $this->finishVoting();
        $this->deleteVotings();
        //check if the game could be ended
        $this->checkTermination();
        if ($this->group->finished !== null) return;
        
        //determine next round
        $start = array_search($this->group->ruleset, $this->phases);
        $nind = $start;
        $day = $this->group->day;
        $valid = false;
        $round = new RoundInfo();
        $round->round = $day;
        $round->phase = $this->phases[$nind];
        foreach ($this->controler as $cont)
            $cont->onLeaveRound($round); //call leave round

        do {
            $nind = ($nind + 1) % count($this->phases);
            if ($nind === 0) $day++;
            $round->round = $day;
            $round->phase = $this->phases[$nind];
            foreach ($this->controler as $cont)
                $valid |= $cont->needToExecuteRound($round);
        }
        while (!$valid && $start != $nind);

        //no valid next round found -> termination
        if (!$valid) {
            $this->checkTermination(true);
            return;
        }
        //set next round
        $this->group->nextPhase($this->phases[$nind], $day);
        foreach ($this->controler as $cont)
            $cont->onStartRound($round); //call start round

        //create votings and update permissions is done in call start round

        //finish :)
    }

    //roles is a array (rolesetKey => count)
    public function startGame(array $roles) { //GameGroup is already created!
        //set phase counter
        $this->group->nextPhase($this->phases[0], 1);
        //get vars
        $user = User::loadAllUserByGroup($this->group->mainGroupId);
        $mainGroup = Group::create($this->group->mainGroupId);
        $player = array();
        $sets = array();
        //load rolesets
        foreach ($this->config->rolesets as $set)
            if (isset($roles[$set->key]))
                for ($i = 0; $i<$roles[$set->key]; ++$i)
                    $sets[] = $set->roles;
        shuffle($sets);
        $setp = 0;
        //create players and assign roles
        foreach ($user as $u) {
            $player[] = Player::createNewPlayer(
                $this->group->id,
                $u->user,
                $u->user == $mainGroup->leader ?
                    $this->config->leader_roles :
                    $sets[$setp++]
            );
        }
        $this->playerBuffer = $player;
        //create chats
        $this->chats = array();
        foreach ($this->config->chats as $chat) {
            $this->chats[] = ChatRoom::createChatRoom(
                $this->game->id, $chat
            );
        }
        //inform game created
        $this->createAllControler();
        $round = new RoundInfo();
        $round->round = 1;
        $round->phase = $this->phases[0];
        foreach ($this->controler as $cont)
            $cont->onGameStarts($round); //call on game starts
        //change phase
        $this->nextRound();
        //finish
    }

    public function finishVoting(ChatRoom $chat = null) {

    }

    private function deleteVotings(ChatRoom $chat = null) {

    }

    private function checkTermination($force = false) {
    }

    //endregion

    //region access helper for RoleBase

    private $playerBuffer = null;

    private function refreshPlayers() {
        if ($this->playerBuffer !== null) return $this->playerBuffer;
        $this->playerBuffer = array();
        foreach (User::loadAllUserByGroup($this->group) as $user) {
            if ($user->player !== null)
                $this->playerBuffer[] = &$user->player;
        }
    }

    public function getPlayer($role = null, $onlyAlive = true) {
        $result = array();
        foreach ($this->refreshPlayers() as &$player) {
            if ($onlyAlive && !$player->alive)
                continue;
            if ($role !== null) {
                if (is_array($role)) {
                    $found = true;
                    foreach ($role as $r) {
                        if (!is_string($r)) continue;
                        if (!$player->hasRole($r)) {
                            $found = false;
                            break;
                        }
                    }
                    if (!$found) continue;
                }
                if (is_string($role)) {
                    if (!$player->haseRole($role))
                        continue;
                }
            }
            $result[] = &$player;
        }
    }

    //endregion
}