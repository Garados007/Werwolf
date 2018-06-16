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
include_once __DIR__ ."/../../db/VoteEntry/VoteEntry.php";
include_once __DIR__ ."/../../db/VisibleRole/VisibleRole.php";

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

    public static function loadConfig($key) {
        if (isset(self::$configBuffer[$key]))
            return self::$configBuffer[$key];
        if (!is_file(__DIR__ . "/${key}/config.json")) 
            return self::$configBuffer[$key] = false;
        $json = json_decode(file_get_contents(__DIR__ . "/${key}/config.json"));
        return self::$configBuffer[$key] = $json;
    }

    public static function getAllModes() {
        $modes = array();
        foreach (new DirectoryIterator(__DIR__) as $finfo) {
            if ($finfo->isDir() && !$finfo->isDot()) {
                $name = $finfo->getFilename();
                if (is_file(__DIR__ ."/${name}/config.json"))
                    $modes[] = $name;
            }
        }
        return $modes;
    }

    public static function loadAllRoles($key) {
        if (isset(self::$roleBuffer[$key]))
            return true;
        $config = self::loadConfig($key);
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
        return array_filter($roles, 
            function ($role) use ($proles) {
                return in_array($role, $proles);
            }
        );
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
        return $this->controler = $controler;
    }

    private function getChats() {
        if ($this->chats !== null) return;
        $chats = array();
        foreach ($this->config->chats as $key) {
            $chats[] = ChatRoom::create(
                ChatRoom::getChatRoomId($this->group->id, $key));
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
        if ($this->group->finished !== null) {
            $this->nextRoundActive = false;
            return;
        }
        
        //determine next round
        $start = array_search($this->group->phase, $this->phases);
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
            $this->nextRoundActive = false;
            return;
        }
        //set next round
        $this->group->nextPhase($this->phases[$nind], $day);
        foreach ($this->controler as $cont)
            $cont->onStartRound($round); //call start round

        //create votings and update permissions is done in call start round

        $this->nextRoundActive = false;
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
            $p = Player::createNewPlayer(
                $this->group->id,
                $u->user,
                $u->user == $mainGroup->leader ?
                    $this->config->leader_roles :
                    $sets[$setp++]
            );
            $player[] = $p;
            $u->setPlayer($p);
            $u->stats->incGameCounter($u->user == $mainGroup->leader);
        }
        $this->playerBuffer = $player;
        //create chats
        $this->chats = array();
        foreach ($this->config->chats as $chat) {
            $this->chats[] = ChatRoom::createChatRoom(
                $this->group->id, $chat
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

    public function startVoting(VoteSetting $voting) {
        $this->createAllControler();
        $voting->startVoting();
        $chat = ChatRoom::create($voting->chat);
        foreach ($this->controler as $cont)
            $cont->onVotingStarts($chat->chatRoom, $voting->voteKey);
    }

    public function finishVoting(ChatRoom $chat = null) {
        //recursive
        if ($chat == null) {
            $this->getChats();
            foreach ($this->chats as $chat)
                $this->finishVoting($chat);
            return;
        }
        //finish each voting
        foreach (VoteSetting::getAllVotings($chat->id) as $voting)
            $this->finishSingleVoting($voting);
    }

    public function finishSingleVoting(VoteSetting $voting) {
        //fetch votes
        $votes = VoteEntry::getVotesBySetting($voting);
        //fetch voter
        $voter = array();
        foreach ($votes as $vote) {
            if (!isset($voter[$vote->target]))
                $voter[$vote->target] = array();
            $voter[$vote->target][] = $vote->voter;
        }
        //fetch raw list
        $rawList = array();
        foreach ($votes as $vote)
            if (isset($rawList[$vote->target]))
                $rawList[$vote->target]++;
            else $rawList[$vote->target] = 1;
        //sort list
        arsort($rawList);
        //transform list
        $transList = array();
        foreach ($rawList as $target => $count)
            $transList[] = array($target, $count);
        //winner
        if (count($transList) > 0) {
            if (count($transList) == 1 || 
                $transList[1][1] != $transList[0][1])
            {
                $voting->endVoting($transList[0][0]);
            }
            else $voting->endVoting(null);
        }
        else $voting->endVoting(null);
        //propagate the winner
        $this->createAllControler();
        foreach ($this->controler as $cont)
            $cont->onVotingStops2(
                ChatRoom::create($voting->chat)->chatRoom,
                $voting->voteKey,
                $transList,
                $voter
            ); //call on voting stops
        //check for finish game
        $this->checkTermination();
        //finish
    }

    private function deleteVotings(ChatRoom $chat = null) {
        //recursive
        if ($chat == null) {
            $this->getChats();
            foreach ($this->chats as $chat)
                $this->deleteVotings($chat);
            return;
        }
        //delete voting
        foreach ($chat->voting as $voting)
            $voting->deleteVoting();
        $chat->voting = array();
    }

    private function checkTermination($force = false) {
        //check if they are more then one fraction left
        $nonEmptyFractions = array();
        foreach ($this->config->fraction as $fraction) {
            $count = 0;
            foreach ($fraction->roles as $role)
                $count += count($this->getPlayer($role));
            if ($count > 0)
                $nonEmptyFractions[] = $fraction;
        }
        if (!$force && count($nonEmptyFractions) >= 2) return;
        //finish
        $this->group->finish();
        $roles = array();
        foreach ($nonEmptyFractions as $fraction)
            foreach ($fraction->roles as $role)
                $roles[] = $role;
        $this->group->setWinner($roles);
        //increase win counter
        foreach ($this->getPlayer($roles) as $player) {
            $user = UserStats::create($player->user);
            $user->incWinCounter();
        }
        //inform game ends
        $this->createAllControler();
        $round = new RoundInfo();
        $round->round = $this->group->day;
        $round->phase = $this->group->phase;
        foreach ($this->controler as $cont)
            $cont->onGameEnds($round, $roles); //call on game ends
        //finish
    }

    //endregion

    //region access helper for RoleBase

    private $playerBuffer = null;

    private function refreshPlayers() {
        if ($this->playerBuffer !== null) return $this->playerBuffer;
        $this->playerBuffer = array();
        foreach (User::loadAllUserByGroup($this->group->mainGroupId) as $user) {
            if ($user->player !== null)
                $this->playerBuffer[] = &$user->player;
        }
        return $this->playerBuffer;
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
                    if (!$player->hasRole($role))
                        continue;
                }
            }
            $result[] = &$player;
        }
        return $result;
    }

    public function setRoomPermission($role, $room, $enable, $write, $visible) {
        if ($role === null) 
            $role = $this->config->roles;
        if (is_array($role)) {
            foreach ($role as $r)
                if ($r !== null)
                    $this->setRoomPermission($r, $room, $enable, $write, $visible);
            return;
        }
        if ($room == null)
            $room = $this->config->chats;
        if (is_array($room)) {
            foreach ($room as $r)
                if ($r !== null)
                    $this->setRoomPermission($role, $r, $enable, $write, $visible);
        }
        $this->getChats();
        foreach ($this->chats as $chat)
            if ($chat->chatRoom == $room) {
                $perm = new ChatPermission(
                    $chat->id,
                    $role,
                    $enable,
                    $enable && $write,
                    $enable && $visible);
                $chat->addPermission($perm);
                return;
            }
    }

    public function createVoting($room, $name, array $targets, $start = null, $end = null) {
        $this->getChats();
        foreach ($this->chats as $chat)
            if ($chat->chatRoom == $room) {
                $enabled = array();
                foreach ($this->controler as $cont)
                    if ($cont->canVote($room, $name))
                        foreach ($this->getPlayer($cont->roleName, true) as $player) {
                            if (!in_array($player->id, $enabled))
                                $enabled[] = $player->id;
                        }
                $targ = array();
                foreach ($targets as $t)
                    if (is_int($t))
                        $targ[] = $t;
                    elseif ($t instanceof Player)
                        $targ[] = $t->id;
                $voting = $chat->createVoting($name, $start, $end, $enabled, $targ);
                foreach ($this->controler as $cont)
                    $cont->onVotingCreated($room, $name);
                return;
            }

    }

    public function addRoleVisibility($user, $targets, $roles) {
        if ($user == null) $user = $this->getPlayer();
        if (is_array($user)) {
            foreach ($user as $u)
                $this->addRoleVisibility($u, $targets, $roles);
            return;
        }
        if ($targets == null) $targets = $this->getPlayer();
        if (is_array($targets)) {
            foreach ($targets as $t)
                $this->addRoleVisibility($user, $t, $roles);
            return;
        }
        if (!($user instanceof Player))
            $user = Player::create($user);
        if (!($targets instanceof Player))
            $targets = Player::create($targets);
        if ($roles === null) {
            $roles = array();
            foreach ($targets->roles as $role)
                $roles[] = $role->roleKey;
        }
        if (!is_array($roles)) $roles = array($roles);
        $roles = array_intersect($targets->getRoleKeys(), $roles);
        VisibleRole::addRoles($user, $targets, $roles);
    }

    //endregion
}