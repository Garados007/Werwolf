<?php

include_once __DIR__ . '/../RoleBase.php';

class werewolf_villager extends RoleBase {
    public function __construct() {
        $this->roleName = 'villager';
        $this->canStartNewRound = false;
        $this->canStartVotings = false;
        $this->canStopVotings = false;
        $this->isFractionRole = false;
    }

    public function onStartRound(RoundInfo $round) {
        if ($round->phase == 'd:major' && $round->round == 1) {
            $this->setRoomPermission('village', true, true, true);
            $this->informVoting('village', 'major', 
                $this->getPlayer('villager', true)
            );
        }
        if ($round->phase == 'd:villge') {
            $this->setRoomPermission('village', true, true, true);
            $this->informVoting('village', 'kill', 
                $this->getPlayer('villager', true)
            );
        }
    }

    public function onLeaveRound(RoundInfo $round) {
        
    }

    public function needToExecuteRound(RoundInfo $round) {
        return $round->phase == 'd:villge' ||
            ($round->round == 1 && $round->phase == 'd:major');
    }

    public function isWinner($winnerRole, PlayerInfo $player) {
        return false; //use fractions
    }

    public function canVote($room, $name) {
        return $room == 'village' && 
            ($name == 'kill' || $name == 'major');
    }

    public function onVotingCreated($room, $name) {

    }

    public function onVotingStarts($room, $name) {

    }

    public function onVotingStops($room, $name, array $result) {
        if ($room == 'village' && $name == 'kill') {
            $result = $this->filterTopScore($result);
            if (count($result) == 0) return;
            if (count($result) > 1) {
                if (count($this->getPlayer('major', true)) > 0)
                    $this->informVoting('village', 'majkill', $result);
                else $this->informVoting('village', 'kill', $result);
            }
            else {
                $player = $result[0];
                $player->addRole('vic_vill');
            }
        }
        if ($room == 'village' && $name == 'major') {
            $result = $this->filterTopScore($result);
            if (count($result) == 0) return;
            if (count($result) > 1) {
                $this->informVoting('village', 'major', $result);
            }
            else {
                $player = $result[0];
                $player->addRole('major');
                $this->addRoleVisibility(null, $player, 'major');
            }
        }
    }

    public function onGameStarts(RoundInfo $round) {
        parent::onGameStarts($round);
        $this->setRoomPermission(array(
            "main"
        ), true, true, true);
    }

    public function onGameEnds(RoundInfo $round, array $teams) {

    }
}