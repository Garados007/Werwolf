<?php

include_once __DIR__ . '/../RoleBase.php';

class villager extends RoleBase {
    public function __construct() {
        $this->roleName = 'villager';
        $this->canStartNewRound = false;
        $this->canStartVoting = false;
        $this->canStopVoting = false;
        $this->isFractionRole = false;
    }

    public function onStartRound(RoundInfo $round) {
        if ($round->phase == 'd:vote') {
            $this->setRoomPermission('village', true, true, true);
            $this->informVoting('village', 'kill', 
                $this->getPlayer('villager', true));
        }
    }

    public function onLeaveRound(RoundInfo $round) {
        
    }

    public function needToExecuteRound(RoundInfo $round) {
        return $round->phase == 'd:vote';
    }

    public function isWinner($winnerRole, PlayerInfo $player) {
        return false; //use fractions
    }

    public function canVote($room, $name) {
        return $room == 'village' && $name == 'kill';
    }

    public function onVotingCreated($room, $name) {

    }

    public function onVotingStarts($room, $name) {

    }

    public function onVotingStops($room, $name, array $result) {
        if ($room == 'village' && ($name == 'kill' || $name == 'kill2')) {
            if (count($result) == 0) return;
            if (count($result) > 1 && $result[0][1] == $result[1][1]) {
                $targets = array();
                for ($i = 0; $i<count($result); ++$i)
                    if ($result[$i][1] == $result[0][1])
                        $targets[] = Player::create($result[$i][0]);
                    else break;
                $this->informVoting('village', 'kill2', $targets);
            }
            else {
                $player = Player::create($result[0][0]);
                $player->kill(false);
            }
        }
    }

    public function onGameStarts(RoundInfo $round) {

    }

    public function onGameEnds(RoundInfo $round, array $teams) {

    }
}