<?php

include_once __DIR__ . '/../RoleBase.php';

class werewolf_witch_hp extends RoleBase {
    public function __construct() {
        $this->roleName = 'witch_hp';
        $this->canStartNewRound = false;
        $this->canStartVotings = false;
        $this->canStopVotings = false;
        $this->isFractionRole = false;
    }

    public function onStartRound(RoundInfo $round) {
        if ($round->phase == 'n:witch') {
            if (count($this->getPlayer('witch_hp', true)) == 0) return;
            $this->informVoting('witch', 'hp', 
                $this->getPlayer('vic_wolf', true)
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
        return $room == 'witch' && $name == 'hp';
    }

    public function onVotingCreated($room, $name) {

    }

    public function onVotingStarts($room, $name) {

    }

    public function onVotingStops2($room, $name, array $result, array $voter) {
        if ($room == 'witch' && $name == 'hp') {
            $result = $this->filterTopScore($result);
            if (count($result) == 0) return;
            foreach ($result as $player) {
                $player->removeRole('vic_wolf');
                foreach ($voter[$player->id] as $vid)
                    Player::create($vid)->removeRole('witch_hp');
            }
        }
    }

    public function onGameStarts(RoundInfo $round) {
        //parent::onGameStarts($round);
        foreach ($this->getPlayer('witch_hp', true) as $player)
            $this->addRoleVisibility($player, $player, 'witch_hp');
        
    }

    public function onGameEnds(RoundInfo $round, array $teams) {

    }
}