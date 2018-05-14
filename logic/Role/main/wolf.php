<?php

include_once __DIR__ . '/../RoleBase.php';

class main_wolf extends RoleBase {
    public function __construct() {
        $this->roleName = 'wolf';
        $this->canStartNewRound = false;
        $this->canStartVotings = false;
        $this->canStopVotings = false;
        $this->isFractionRole = false;
    }

    public function onStartRound(RoundInfo $round) {
        if ($round->phase == 'n:wolfvo') {
            $this->setRoomPermission('wolfkill', true, true, true);
            $this->informVoting('wolfkill', 'kill', 
                $this->getPlayer('fvillage', true));
        }
    }

    public function onLeaveRound(RoundInfo $round) {
        
    }

    public function needToExecuteRound(RoundInfo $round) {
        return $round->phase == 'n:wolfvo';
    }

    public function isWinner($winnerRole, PlayerInfo $player) {
        return false; //use fractions
    }

    public function canVote($room, $name) {
        return $room == 'wolfkill' && $name == 'kill';
    }

    public function onVotingCreated($room, $name) {

    }

    public function onVotingStarts($room, $name) {

    }

    public function onVotingStops($room, $name, array $result) {
        if ($room == 'wolfkill' && $name == 'kill') {
            if (count($result) == 0) return;
            if (count($result) > 1 && $result[0][1] == $result[1][1]) {
                $targets = array();
                for ($i = 0; $i<count($result); ++$i)
                    if ($result[$i][1] == $result[0][1])
                        $targets[] = Player::create($result[$i][0]);
                    else break;
                $this->informVoting('village', 'kill', $targets);
            }
            else {
                $player = Player::create($result[0][0]);
                $player->kill(true);
            }
        }
    }

    public function onGameStarts(RoundInfo $round) {
        parent::onGameStarts($round);
    }

    public function onGameEnds(RoundInfo $round, array $teams) {

    }
}