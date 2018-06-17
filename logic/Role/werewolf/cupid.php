<?php

include_once __DIR__ . '/../RoleBase.php';

class werwolf_cupid extends RoleBase {
    public function __construct() {
        $this->roleName = 'cupid';
        $this->canStartNewRound = false;
        $this->canStartVotings = false;
        $this->canStopVotings = false;
        $this->isFractionRole = false;
    }

    public function onStartRound(RoundInfo $round) {
        if ($round->phase == 'n:cupid' && $round->round == 1) {
            $this->setRoomPermission('cupid', true, true, true);
            $this->informVoting('cupid', 'love', 
                $this->filterPlayer(
                    $this->getPlayer('villager'),
                    array(),
                    array('amorous')
                )
            );
        }
    }

    public function onLeaveRound(RoundInfo $round) {
        
    }

    public function needToExecuteRound(RoundInfo $round) {
        return $round->phase == 'n:cupid' && $round->round == 1 &&
            count($this->getPlayer('cupid', true)) > 0 &&
            count($this->getPlayer('villager', true)) >= 2;
    }

    public function isWinner($winnerRole, PlayerInfo $player) {
        return false; //use fractions
    }

    public function canVote($room, $name) {
        return $room == 'cupid' && $name == 'love';
    }

    public function onVotingCreated($room, $name) {

    }

    public function onVotingStarts($room, $name) {

    }

    public function onVotingStops($room, $name, array $result) {
        if ($room == 'cupid' && $name == 'love') {
            $result = $this->filterTopScore($result);
            if (count($result) == 0) return;
            if (count($result) > 1) {
                $this->informVoting('cupid', 'love', $result);
            }
            else {
                $all = $this->getPlayer(null);
                $player = $result[0];
                $player->addRole('amorous');
                $this->addRoleVisibility(
                    $this->filterPlayer($all,
                        array(
                            'cupid',
                            'amorous',
                            'storytel'
                        ),
                        array()
                    ),
                    $player,
                    'amorous'
                );
                $this->informVoting('cupid', 'love2',
                    $this->filterPlayer(
                        $this->getPlayer('villager'),
                        array(),
                        array('amorous')
                    )
                );
            }
        }
        if ($room == 'cupid' && $name == 'love2') {
            $result = $this->filterTopScore($result);
            if (count($result) == 0) return;
            if (count($result) > 1) {
                $this->informVoting('cupid', 'love2', $result);
            }
            else {
                $all = $this->getPlayer(null);
                $player = $result[0];
                $player->addRole('amorous');
                $this->addRoleVisibility(
                    $this->filterPlayer($all,
                        array(
                            'cupid',
                            'amorous',
                            'storytel'
                        ),
                        array()
                    ),
                    $this->filterPlayer($all, array('amorous'), array()),
                    'amorous'
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