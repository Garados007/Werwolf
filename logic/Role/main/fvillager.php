<?php

include_once __DIR__ . '/../RoleBase.php';

class main_fvillager extends RoleBase {
    public function __construct() {
        $this->roleName = 'fvillager';
        $this->canStartNewRound = false;
        $this->canStartVoting = false;
        $this->canStopVoting = false;
        $this->isFractionRole = true;
    }
}