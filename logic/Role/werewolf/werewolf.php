<?php

include_once __DIR__ . '/../RoleBase.php';

class werwolf_villager extends RoleBase {
    public function __construct() {
        $this->roleName = 'werwolf';
        $this->canStartNewRound = false;
        $this->canStartVotings = false;
        $this->canStopVotings = false;
        $this->isFractionRole = false;
    }

    public function onStartRound(RoundInfo $round) {
        if ($round->phase == 'n:werewo') {
            $this->setRoomPermission('werewolf', true, true, true);
            $this->informVoting('werewolf', 'kill', 
                $this->getPlayer('villager', true)
            );
        }
    }

    public function onLeaveRound(RoundInfo $round) {
        
    }

    public function needToExecuteRound(RoundInfo $round) {
        return $round->phase == 'n:werewo' &&
            count($this->getPlayer('werewolf', true)) > 0;
    }

    public function isWinner($winnerRole, PlayerInfo $player) {
        return false; //use fractions
    }

    public function canVote($room, $name) {
        return $room == 'werewolf' && $name == 'kill';
    }

    public function onVotingCreated($room, $name) {

    }

    public function onVotingStarts($room, $name) {

    }

    public function onVotingStops($room, $name, array $result) {
        if ($room == 'werewolf' && $name == 'kill') {
            $result = $this->filterTopScore($result);
            if (count($result) == 0) return;
            if (count($result) > 1) {
                $this->informVoting('werwolf', 'kill', $result);
            }
            else {
                $player = $result[0];
                $player->addRole('vic_wolf');
                $this->addRoleVisibility(
                    array_merge(
                        $this->getPlayer('storytel'),
                        $this->getPlayer('witch')
                    ),
                    $player,
                    null
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