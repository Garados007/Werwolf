<?php

include_once __DIR__ . '/../db.php';
include_once __DIR__ . '/../JsonExport/JsonExport.php';

class UserConfig extends JsonExport {
    //user id
    public $userId;
    //config
    public $config;

    private static $cache = array();
    private function __construct(){}

    public static function create($userId) {
		if (isset(self::$cache[$userId]))
			return self::$cache[$userId];
        $cur = new UserConfig();
        
        $cur->jsonNames = array('userId', 'config');
        $result = DB::executeFormatFile(
            __DIR__ . '/sql/loadConfig.sql',
            array(
                "id" => $userId
            )
        );
        if ($entry = $result->getResult()->getEntry()) {
            $cur->userId = intval($entry["User"]);
            $cur->config = $entry["Config"];
        }
		else {
			$result->free();
			$cur = null;
		}

		return self::$cache[$userId] = $cur;
    }

    public static function createNewConfig($userId, $config) {
		$result = DB::executeFormatFile(
			__DIR__ . '/sql/createConfig.sql',
			array(
                "id" => $userId,
                "config" => $config
			)
		);
		echo DB::getError();
        if ($set = $result->getResult()) $set->free(); //insert stat
        $result->free();
        return self::create($userId);
    }
}