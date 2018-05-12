<?php

include_once __DIR__ . '/../db.php';
include_once __DIR__ . '/../JsonExport/JsonExport.php';

class UserStats extends JsonExport {
    //user id
    public $userId;
    //first game date
    public $firstGame;
    //date of last game
    public $lastGame;
    //total count of games
    public $gameCount;
    //total count of wins
    public $winningCount;
    //total count of self-moderated games
    public $moderatedCount;
    //date of last online
    public $lastOnline;
    //unique db id of ai info
    public $aiId;
    //unique name key of ai info
    public $aiNameKey;
    //control class of the ai
    public $aiControlClass;

    private static $cache = array();
    private function __construct(){}

    public static function create($userId) {
		if (isset(self::$cache[$id]))
			return self::$cache[$id];
        $cur = new UserStats();
        
        $cur->jsonNames = array('userId', 'firstGame', 'lastGame',
            'gameCount', 'winningCount', 'moderatedCount', 'lastOnline',
            'aiId', 'aiNameKey', 'aiControlClass');
        $result = DB::executeFormatFile(
            __DIR__ . '/sql/loadStats.sql',
            array(
                "id" => $userID
            )
        );
        if ($entry = $result->getResult()->getEntry()) {
            $cur->userId = intval($entry["UserId"]);
            $cur->firstGame = $entry["FirstGame"];
            $cur->lastGame = $entry["LastGame"];
            $cur->gameCount = $entry["GameCount"];
            $cur->winningCount = $entry["WinningCount"];
            $cur->moderatedCount = $entry["ModeratedCount"];
            $cur->lastOnline = $entry["LastOnline"];
            $cur->aiId = $entry["AiId"];
            $cur->aiNameKey = $entry["AiNameKey"];
            $cur->aiControlClass = $entry["AiControlClass"];
        }
		else {
			$result->free();
			$cur = null;
		}

		return self::$cache[$id] = $cur;
    }

    public static function createNewUserStats($userId) {
		$result = DB::executeFormatFile(
			__DIR__ . '/sql/createStats.sql',
			array(
                "id" => $userId,
                "aiName" => null,
                "aiClass" => null
			)
		);
		echo DB::getError();
        if ($set = $result->getResult()) $set->free(); //insert stat
        $result->free();
        return self::create($userId);
    } 
    
    public static function createNewAiStats($userId, $nameKey, $controlClass) {
		$result = DB::executeFormatFile(
			__DIR__ . '/sql/createStats.sql',
			array(
                "id" => $userId,
                "aiName" => $nameKey,
                "aiClass" => $controlClass
			)
		);
		echo DB::getError();
        if ($set = $result->getResult()) $set->free(); //insert ai
        if ($set = $result->getResult()) $set->free(); //select id
        if ($set = $result->getResult()) $set->free(); //insert stat
        $result->free();
        return self::create($userId);
    } 
    
    public function setOnline() {
        $this->lastOnline = time();
        $result = DB::executeFormatFile(
            __DIR__ . '/sql/setOnline.sql',
            array(
                "id" => $this->userId,
                "time" => $this->lastOnline
            )
        )->free();
    }

    public function incGameCounter($moderator) {
        $this->gameCount++;
        $time = time();
        $this->lastGame = $time;
        if ($this->firstGame === null) $this->firstGame = $time;
        if ($moderator)
            $this->moderatedCount++;
        $result = DB::executeFormatFile(
            __DIR__ . '/sql/incGameCounter.sql',
            array(
                "id" => $this->userId,
                "mod" => $moderator,
                "first" => $this->firstGame,
                "last" => $this->lastGame
            )
        )->free();
    }

    public function incWinCounter() {
        $this->winningCount++;
        $result = DB::executeFormatFile(
            __DIR__ . '/sql/incWinCounter.sql',
            array(
                "id" => $this->userId
            )
        )->free();
    }
}