<?php

include_once __DIR__ . '/../RoleBase.php';

class main_fvillage extends RoleBase {
    public function __construct() {
        $this->roleName = 'fvillage';
        $this->canStartNewRound = false;
        $this->canStartVotings = false;
        $this->canStopVotings = false;
        $this->isFractionRole = true;
    }
}