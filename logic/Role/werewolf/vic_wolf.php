<?php

include_once __DIR__ . '/VictimBase.php';

class werewolf_vic_wolf extends werewolf_VictimBase {
    public function __construct() {
        $this->roleName = 'vic_wolf';
    }
}