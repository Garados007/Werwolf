<?php

include_once __DIR__ . '/../RoleBase.php';

class werwolf_VictimBase extends RoleBase {
    public function __construct() {
    }

    public function needToExecuteRound(RoundInfo $round) {
        if ($round->phase == 'd:kill' || $round->phase == 'n:kill') {
            $all = $this->getPlayer($this->roleName);
            if (count($all) == 0) return false;
            if (count($this->filterPlayer($all, array('amorous'), array())) > 0) {
                $all = array_merge(
                    $all,
                    $this->getPlayer('amorous')
                );
            }
            $any = false;
            $storytel = $this->getPlayer('storytel');
            foreach ($this->filterPlayer($all, array('hunter'), array()) as $player) {
                $player->removeRole($this->roleName);
                $player->addRole('vic_hunt');
                $this->addRoleVisibility(
                    $storytel,
                    $player,
                    null
                );
                $any = true;
            }
            foreach ($this->filterPlayer($all, array('major'), array()) as $player) {
                $player->removeRole($this->roleName);
                $player->addRole('vic_majr');
                $this->addRoleVisibility(
                    $storytel,
                    $player,
                    null
                );
                $any = true;
            }
            foreach ($this->filterPlayer($all, array(), array('hunter', 'major')) as $player) {
                $player->kill(false);
            }
            return $any;
        }
        return false;
    }

    public function onGameStarts(RoundInfo $round) {
    }
}