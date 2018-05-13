<?php

include_once __DIR__ . '/../RoleBase.php';

class main_storytel extends RoleBase {
    public function __construct() {
        $this->roleName = 'storytel';
        $this->canStartNewRound = true;
        $this->canStartVotings = true;
        $this->canStopVotings = true;
        $this->isFractionRole = false;
    }
}