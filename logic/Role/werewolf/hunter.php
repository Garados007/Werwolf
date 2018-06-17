<?php

include_once __DIR__ . '/../RoleBase.php';

class werwolf_hunter extends RoleBase {
    public function __construct() {
        $this->roleName = 'hunter';
        $this->canStartNewRound = false;
        $this->canStartVotings = false;
        $this->canStopVotings = false;
        $this->isFractionRole = false;
    }

    public function onStartRound(RoundInfo $round) {
        
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
    }

    public function onGameEnds(RoundInfo $round, array $teams) {

    }
}