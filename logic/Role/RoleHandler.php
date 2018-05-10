<?php

include_once __DIR__ . "/RoleBase.php";
include_once __DIR__ ."/../../db/User/User.php";
include_once __DIR__ ."/../../db/Player/Player.php";

class RoleHandler {
    private static $roleBuffer = array();
    private static $configBuffer = array();
    private $group;

    public function __construct($group) {
        if (!is_int($group)) throw new Exception ("group is not a number");
        $this->group = $group;
    }

    private static function loadConfig($key) {
        if (isset(self::$configBuffer[$key]))
            return self::$configBuffer[$key];
        if (!is_file(__DIR__ . "/${key}/config.json")) 
            return self::$configBuffer[$key] = false;
        $json = json_decode(file_get_contents(__DIR__ . "/${key}/config.json"));
        return self::$configBuffer[$key] = $json;
    }

    public function loadAllRoles($key) {
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

    public function getRoles($key) {
        return isset(self::$roleBuffer[$key]) ? self::$roleBuffer[$key] : false;
    }

    //region main control functions

    public function nextRound($group) {

    }

    public function startGame($group) {

    }

    public function finishVoting($group) {

    }

    //endregion

    //region access helper for RoleBase

    private $playerBuffer = null;

    private function refreshPlayers() {
        if ($this->playerBuffer !== null) return $this->playerBuffer;
        $this->playerBuffer = array();
        foreach (User::loadAllUserByGroup($this->group) as $user) {
            $player = new Player($user->game, $user->user);
            $this->playerBuffer[] = &$player;
        }
    }

    public function getPlayer($role, $onlyAlive) {
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