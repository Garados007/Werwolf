<?php

include_once __DIR__ . '/../RoleBase.php';

class werewolf_witch_kp extends RoleBase {
    public function __construct() {
        $this->roleName = 'witch_kp';
        $this->canStartNewRound = false;
        $this->canStartVotings = false;
        $this->canStopVotings = false;
        $this->isFractionRole = false;
    }

    public function onStartRound(RoundInfo $round) {
        if ($round->phase == 'n:witch') {
            if (count($this->getPlayer('witch_kp', true)) == 0) return;
            $this->informVoting('witch', 'kp', 
                $this->filterPlayer(
                    $this->getPlayer('villager', true),
                    array(),
                    array(
                        'witch',
                        'vic_wolf'
                    )
                )
            );
        }
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
        return $room == 'witch' && $name == 'kp';
    }

    public function onVotingCreated($room, $name) {

    }

    public function onVotingStarts($room, $name) {

    }

    public function onVotingStops2($room, $name, array $result, array $voter) {
        if ($room == 'witch' && $name == 'kp') {
            $result = $this->filterTopScore($result);
            if (count($result) == 0) return;
            $storytel = $this->getPlayer('storytel');
            foreach ($result as $player) {
                $player->addRole('vic_witc');
                $this->addRoleVisibility(
                    $storytel,
                    $player,
                    null
                );
                foreach ($voter[$player->id] as $vid)
                    Player::create($vid)->removeRole('witch_kp');
            }
        }
    }

    public function onGameStarts(RoundInfo $round) {
        //parent::onGameStarts($round);
        foreach ($this->getPlayer('witch_kp', true) as $player)
            $this->addRoleVisibility($player, $player, 'witch_kp');
        
    }

    public function onGameEnds(RoundInfo $round, array $teams) {

    }
}