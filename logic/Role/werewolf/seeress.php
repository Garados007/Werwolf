<?php

include_once __DIR__ . '/../RoleBase.php';

class werewolf_seeress extends RoleBase {
    public function __construct() {
        $this->roleName = 'seeress';
        $this->canStartNewRound = false;
        $this->canStartVotings = false;
        $this->canStopVotings = false;
        $this->isFractionRole = false;
    }

    public function onStartRound(RoundInfo $round) {
        if ($round->phase == 'n:seeres') {
            $this->setRoomPermission('seeress', true, true, true);
            $this->informVoting('seeress', 'view', 
                $this->filterPlayer(
                    $this->getPlayer('villager', true),
                    array(),
                    array('seeress')
                )
            );
        }
    }

    public function onLeaveRound(RoundInfo $round) {
        
    }

    public function needToExecuteRound(RoundInfo $round) {
        return $round->phase == 'n:seeres' &&
            count($this->getPlayer('seeress', true)) > 0;
    }

    public function isWinner($winnerRole, PlayerInfo $player) {
        return false; //use fractions
    }

    public function canVote($room, $name) {
        return $room == 'seeress' && $name == 'view';
    }

    public function onVotingCreated($room, $name) {

    }

    public function onVotingStarts($room, $name) {

    }

    public function onVotingStops($room, $name, array $result) {
        if ($room == 'seeress' && $name == 'view') {
            $result = $this->filterTopScore($result);
            if (count($result) == 0) return;
            if (count($result) > 1) {
                $this->informVoting('seeress', 'view', $result);
            }
            else {
                $player = $result[0];
                $this->addRoleVisibility(
                    $this->getPlayer($this->roleName),
                    $player,
                    array(
                        'werewolf',
                        'villager',
                        'major',
                        'seeress',
                        'cupid',
                        'witch',
                        'litlgirl'
                    )
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