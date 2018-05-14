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
    /**
     * Determines if this role is only used to associate the player
     * to a single fraction. This role contains no logic.
     */
    public $isFractionRole = false;

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
     * Normaly the end game is detected with the fractions defined in
     * config.json. This function is only called, when someone calls
     * the function endGame() for specific endGame.
     * $winnerRole has always the same value as the role who calls
     * endGame().
     */
    public function isWinner($winnerRole) {
        return false;
    }

    /**
     * Determine if a player with this specific role can vote in this room
     */
    public function canVote($room, $name) {
        return false;
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
        $this->addRoleVisibility(
            $this->getPlayer($this->roleName),
            $this->getPlayer($this->roleName),
            $this->roleName
        );
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
     * Normaly a end game situation is detected with the fractions
     * defined in config.json, so this call is not necessary.
     */
    protected function endGame() {
        $winner = $this->roleName;

    }

    /**
     * Returns a list of Player objects with this given roles. If onlyAlive
     * is checked then only living players are returned.
     */
    protected function getPlayer($role, $onlyAlive = true) {
        return $this->roleHandler->getPlayer($role, $onlyAlive);
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
        $this->roleHandler->setRoomPermission(
            $this->roleName, $room, $enable, $write, $visible);
    }

    /**
     * Inform the system to create a new voting when possible.
     * The system checks with canVote() for all player who can vote
     * in this voting.
     */
    protected function informVoting($room, $name, array $targets, $start = null, $end = null) {
        $this->roleHandler->createVoting(
            $room, $name, $targets, $start, $end
        );
    }

    /**
     * Adds for each user (null means every user) (Player-object or id)
     * the visibility of roles from each target (null means every target with
     * this role) (Player-object or id). $roles can be a single role, an array
     * of roles or null for each role of the specified target.
     * The visibility is only added for current existing roles.
     */
    protected function addRoleVisibility($user, $targets, $roles) {
        $this->roleHandler->addRoleVisibility($user, $targets, $roles);
    }
    //endregion
}