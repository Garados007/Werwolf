<?php

include_once __DIR__ . '/../RoleBase.php';

class werwolf_vic_majr extends RoleBase {
    public function __construct() {
        $this->roleName = 'vic_majr';
        $this->canStartNewRound = false;
        $this->canStartVotings = false;
        $this->canStopVotings = false;
        $this->isFractionRole = false;
    }

    public function onStartRound(RoundInfo $round) {
        if ($round->phase == 'n:kill' || $round->phase == 'd:kill') {
            if (count($this->getPlayer('vic_majr', true)) == 0) return;
            $this->setRoomPermission('kill', true, true, true);
            $this->informVoting('kill', 'majr', 
                $this->filterPlayer(
                    $this->getPlayer('villager', true),
                    array(),
                    array('vic_hunt', 'vic_majr')
                )
            );
        }
    }

    public function onLeaveRound(RoundInfo $round) {
        
    }

    public function needToExecuteRound(RoundInfo $round) {
        return ($round->phase == 'n:kill' || $round->phase == 'd:kill') &&
            count($this->getPlayer('vic_majr', true)) > 0;
    }

    public function isWinner($winnerRole, PlayerInfo $player) {
        return false; //use fractions
    }

    public function canVote($room, $name) {
        return $room == 'kill' && $name == 'majr';
    }

    public function onVotingCreated($room, $name) {

    }

    public function onVotingStarts($room, $name) {

    }

    public function onVotingStops($room, $name, array $result) {
        if ($room == 'kill' && $name == 'majr') {
            $result = $this->filterTopScore($result);
            if (count($result) == 0) {
                foreach ($this->getPlayer('vic_majr') as $player)
                    $player->kill(false);
                return;
            }
            if (count($result) > 1) {
                $this->informVoting('kill', 'majr', $result);
            }
            else {
                foreach ($this->getPlayer('vic_majr') as $player)
                    $player->kill(false);
                $player = $result[0];
                $player->addRole('major');
                $this->addRoleVisibility(
                    null,
                    $player,
                    'major'
                );
            }
        }
    }

    public function onGameStarts(RoundInfo $round) {
        parent::onGameStarts($round);
    }

    public function onGameEnds(RoundInfo $round, array $teams) {

    }
}