<?php
include_once __DIR__ . "/RoundInfo.php";
include_once __DIR__ . "/PlayerInfo.php";

class RoleBase {
    /**
     * The public name key of this role
     */
    public $roleName;
    /**
     * Its used for the access to the role handler
     */
    public $roleHandler;

    //region permissions
    /**
     * Determines if a player with the current role can start a
     * new round
     */
    public $canStartNewRound = false;
    /**
     * Determines if a player with the current role can start
     * votings
     */
    public $canStartVotings = false;
    /**
     * Determines if a player with the current role can stop
     * votings
     */
    public $canStopVotings = false;

    //endregion

    //region to inherit
    /**
     * This function is called, whenever a round starts.
     */
    public function onStartRound(RoundInfo $round) {}

    /**
     * This function is called, whenever a round is finished.
     */
    public function onLeaveRound(RoundInfo $round) {
        
    }

    /**
     * Checks if the given rounds needs to be executed.
     */
    public function needToExecuteRound(RoundInfo $round) {
        return false;
    }

    /**
     * Determines of a player with the current role could also be a winner, 
     * if the given team wins. This function is called for each player.
     */
    public function isWinner($winnerRole, PlayerInfo $player) {
        return false;
    }

    /**
     * A single player is choosen to be killed.
     */
    public function onPlayerKill(PlayerInfo $player) {

    }

    /**
     * This function is called, when a voting is created.
     */
    public function onVotingCreated($room, $name) {

    }

    /**
     * This function is called, when a voting is declared to start.
     */
    public function onVotingStarts($room, $name) {

    }

    /**
     * This functions is called, when a voting is declared to stop.
     * The result is a descending sorted list of a Tuple (Target Id, Count
     * of votes).
     */
    public function onVotingStops($room, $name, array $result) {

    }

    /**
     * This funtion is called when a single game starts. Its used
     * to initialize some variables.
     */
    public function onGameStarts(RoundInfo $round) {

    }

    /**
     * This function is called when a single game is finished. Its
     * used to cleanup all variables.
     */
    public function onGameEnds(RoundInfo $round, array $teams) {

    }
    //endregion

    //region util functions
    /**
     * Start the end game sequence. Everybody with the current role is
     * declared as winner. Other player can be winner to, but this is
     * determined in isWinner().
     */
    protected function endGame() {
        $winner = $this->roleName;

    }

    /**
     * Returns a list of Player objects with this given roles. If onlyAlive
     * is checked then only living players are returned.
     */
    protected function getPlayer($role, $onlyAlive) {
        $this->roleHandler->getPlayer($role, $onlyAlive);
    }

    /**
     * Set the room entrence permission for this role. If enable is checked
     * this role can read all messages. If write is checked everybody with
     * this role is allowed to write here. If visible is not checked this
     * role is invisible to everybody else in this chat.
     * This Permissions are automaticly removed, when a new round starts
     * (except the exceptions defined in config.json).
     */
    protected function setRoomPermission($room, $enable, $write, $visible) {

    }

    /**
     * Inform the system to create a new voting when possible. The creator
     * is able to vote here. Other people in this room can only see the
     * results.
     */
    protected function informVoting($room, $name) {
        
    }
    //endregion
}