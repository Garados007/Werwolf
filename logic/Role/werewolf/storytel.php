<?php

include_once __DIR__ . '/../RoleBase.php';

class werewolf_storytel extends RoleBase {
    public function __construct() {
        $this->roleName = 'storytel';
        $this->canStartNewRound = true;
        $this->canStartVotings = true;
        $this->canStopVotings = true;
        $this->isFractionRole = false;
    }

    
    public function onStartRound(RoundInfo $round) {
        $this->setRoomPermission(null, true, true, true);
    }

    public function onLeaveRound(RoundInfo $round) {
        
    }

    public function needToExecuteRound(RoundInfo $round) {
        return false;
    }

    public function isWinner($winnerRole, PlayerInfo $player) {
        return false; //use fractions
    }

    public function canVote($room, $name) {
        return false;
    }

    public function onVotingCreated($room, $name) {

    }

    public function onVotingStarts($room, $name) {

    }

    public function onVotingStops($room, $name, array $result) {
        
    }

    public function onGameStarts(RoundInfo $round) {
        parent::onGameStarts($round);
        $this->setRoomPermission(null, true, true, true);
        $this->addRoleVisibility(
            null,
            $this->getPlayer($this->roleName),
            $this->roleName
        );
        $this->addRoleVisibility(
            $this->getPlayer($this->roleName),
            null,
            null
        );
    }

    public function onGameEnds(RoundInfo $round, array $teams) {

    }
}