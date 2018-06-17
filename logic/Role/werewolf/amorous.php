<?php

include_once __DIR__ . '/../RoleBase.php';

class werwolf_amorous extends RoleBase {
    public function __construct() {
        $this->roleName = 'amorous';
        $this->canStartNewRound = false;
        $this->canStartVotings = false;
        $this->canStopVotings = false;
        $this->isFractionRole = false;
    }

    public function onStartRound(RoundInfo $round) {
        if ($round->phase == 'n:amorou' && $round->round == 1) {
            $this->setRoomPermission('amorous', true, true, true);
        }
    }

    public function onLeaveRound(RoundInfo $round) {
        $all = $this->getPlayer('villager');
        $amorous = $this->filterPlayer($all, array('amorous'), array());
        if (count($all) == count($amorous)) {
            $this->endGame();
        }
    }

    public function needToExecuteRound(RoundInfo $round) {
        return $round->phase == 'n:amorou' && $round->round == 1 &&
            count($this->getPlayer('amorous', true)) > 0;
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