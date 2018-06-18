<?php

include_once __DIR__ . '/VictimBase.php';

class werewolf_vic_witc extends werewolf_VictimBase {
    public function __construct() {
        $this->roleName = 'vic_witc';
    }
}