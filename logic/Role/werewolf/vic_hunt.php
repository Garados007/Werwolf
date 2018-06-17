<?php

include_once __DIR__ . '/../RoleBase.php';

class werewolf_vic_hunt extends RoleBase {
    public function __construct() {
        $this->roleName = 'vic_hunt';
        $this->canStartNewRound = false;
        $this->canStartVotings = false;
        $this->canStopVotings = false;
        $this->isFractionRole = false;
    }

    public function onStartRound(RoundInfo $round) {
        if ($round->phase == 'n:kill' || $round->phase == 'd:kill') {
            if (count($this->getPlayer('vic_hunt', true)) == 0) return;
            $this->setRoomPermission('kill', true, true, true);
            $this->informVoting('kill', 'hunt', 
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
            count($this->getPlayer('vic_hunt', true)) > 0;
    }

    public function isWinner($winnerRole, PlayerInfo $player) {
        return false; //use fractions
    }

    public function canVote($room, $name) {
        return $room == 'kill' && $name == 'hunt';
    }

    public function onVotingCreated($room, $name) {

    }

    public function onVotingStarts($room, $name) {

    }

    public function onVotingStops($room, $name, array $result) {
        if ($room == 'kill' && $name == 'hunt') {
            foreach ($this->getPlayer('vic_hunt') as $player)
                $player->kill(false);
            $result = $this->filterTopScore($result);
            if (count($result) == 0) return;
            if (count($this->filterPlayer($result, array('amorous'), array())) > 0)
                $result = array_merge(
                    $result,
                    $this->getPlayer('amorous', true)
                );
            $anyH = false;
            $anyM = false;
            $storytel = $this->getPlayer('storytel');
            foreach ($this->filterPlayer($result, array('hunter'), array()) as $player) {
                $player->addRole('vic_hunt');
                $this->addRoleVisibility(
                    $storytel,
                    $player,
                    null
                );
                $anyH = true;
            }
            foreach ($this->filterPlayer($result, array('major'), array()) as $player) {
                $player->addRole('vic_majr');
                $this->addRoleVisibility(
                    $storytel,
                    $player,
                    null
                );
                $anyM = true;
            }
            foreach ($this->filterPlayer($result, array(), array('hunter', 'major')) as $player) {
                $player->kill(false);
            }
            if ($anyH)
                $this->informVoting('kill', 'hunt', 
                    $this->filterPlayer(
                        $this->getPlayer('villager', true),
                        array(),
                        array('vic_hunt', 'vic_majr')
                    )
                );
            if ($anyM)
                $this->informVoting('kill', 'majr', 
                    $this->filterPlayer(
                        $this->getPlayer('villager', true),
                        array(),
                        array('vic_hunt', 'vic_majr')
                    )
                );
        }
    }

    public function onGameStarts(RoundInfo $round) {
        parent::onGameStarts($round);
    }

    public function onGameEnds(RoundInfo $round, array $teams) {

    }
}