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
    //total ammount of bans
    public $totalBanCount;
    //total sum of full days of all bans
    public $totalBanDays;
    //total count of perma bans
    public $permaBanCount;
    //total count of spoken bans to others
    public $spokenBanCount;

    private static $cache = array();
    private function __construct() {
        $this->jsonNames = array('userId', 'firstGame', 'lastGame',
            'gameCount', 'winningCount', 'moderatedCount', 'lastOnline',
            'aiId', 'aiNameKey', 'aiControlClass',
            'totalBanCount', 'totalBanDays', 'permaBanCount', 'spokenBanCount'
        );
    }

    public static function create($userId) {
		if (isset(self::$cache[$userId]))
			return self::$cache[$userId];
        $cur = new UserStats();
        
        $result = DB::executeFormatFile(
            __DIR__ . '/sql/loadStats.sql',
            array(
                "id" => $userId
            )
        );
        if ($entry = $result->getResult()->getEntry()) {
            self::readStatData($cur, $entry);
        }
		else {
			$result->free();
			$cur = null;
		}

		return self::$cache[$userId] = $cur;
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

    public static function getTopStats($filter) {
        if (array_search($filter, [ 
            'mostGames', 
            'mostWinGames', 
            'mostModGames', 
            'topWinner',
            'topMod',
            'mostBanned',
            'longestBanned',
            'mostPermaBanned' 
            ])<0) return [];
        $result = DB::executeFormatFile(
            __DIR__ . '/sql/topStats.sql',
            array(
                "filter" => $filter
            )
        );
        $list = array();
        $set = $result->getResult();
        while ($entry = $set->getEntry()) {
            $userId = intval($entry["UserId"]);
            if (isset(self::$cache[$userId]))
                $list[] = self::$cache[$userId];
            else {
                $cur = new UserStats();
                self::readStatData($cur, $entry);
                $list[] = $cur;
                self::$cache[$userId] = $cur;
            }
        }
        $result->free();
        return $list;
    }

    private function readStatData(&$cur, &$entry) {
        $cur->userId = intval($entry["UserId"]);
        $cur->firstGame = intvaln($entry["FirstGame"]);
        $cur->lastGame = intvaln($entry["LastGame"]);
        $cur->gameCount = intval($entry["GameCount"]);
        $cur->winningCount = intval($entry["WinningCount"]);
        $cur->moderatedCount = intval($entry["ModeratorCount"]);
        $cur->lastOnline = intval($entry["LastOnline"]);
        $cur->aiId = intvaln($entry["AiId"]);
        $cur->aiNameKey = $entry["AiNameKey"];
        $cur->aiControlClass = $entry["AiControlClass"];
        $cur->totalBanCount = intval($entry['TotalBanCount']);
        $cur->totalBanDays = intval($entry['TotalBanDays']);
        $cur->permaBanCount = intval($entry['PermaBanCount']);
        $cur->spokenBanCount = intval($entry['SpokenBanCount']);
    }
}