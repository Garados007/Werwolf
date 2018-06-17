<?php

include_once __DIR__ . '/../RoleBase.php';

class werewolf_major extends RoleBase {
    public function __construct() {
        $this->roleName = 'major';
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
        return $room == 'village' && $name == 'majkill';
    }

    public function onVotingCreated($room, $name) {

    }

    public function onVotingStarts($room, $name) {

    }

    public function onVotingStops($room, $name, array $result) {
        if ($room == 'village' && $name == 'majkill') {
            $result = $this->filterTopScore($result);
            if (count($result) == 0) return;
            if (count($result) > 1) {
                $this->informVoting('village', 'majkill', $result);
            }
            else {
                $player = $result[0];
                $player->addRole('vic_vill');
                $this->addRoleVisibility(
                    $this->getPlayer('storytel'),
                    $player,
                    null
                );
            }
        }
    }

    public function onGameStarts(RoundInfo $round) {
    }

    public function onGameEnds(RoundInfo $round, array $teams) {

    }
}