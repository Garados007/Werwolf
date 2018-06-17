<?php

include_once __DIR__ . '/../RoleBase.php';

class werewolf_fvillage extends RoleBase {
    public function __construct() {
        $this->roleName = 'fvillage';
        $this->canStartNewRound = false;
        $this->canStartVotings = false;
        $this->canStopVotings = false;
        $this->isFractionRole = true;
    }

    public function onGameStarts(RoundInfo $round) {
        /*no call of parent onGameStarts because the role fvillage
          is to determine the fractions. If someone could see this
          role, so someone can determine itself which fractions the player
          belongs to or not.
        */
        //parent::onGameStarts($round);
    }
}