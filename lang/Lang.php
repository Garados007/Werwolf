<?php

include_once dirname(__FILE__).'/../config.php';

class Lang {
	private static $current = null;
	
	private static $data = null;
	
	public static function SetLanguage($token) {
		if (!is_dir(dirname(__FILE__)."/{$token}")) return false;
		setcookie('Language', $token, time()+3600*24*365, '/'.URI_PATH);
		self::$current = $token;
		$data = array();
	}
	
	public static function GetLanguage() {
		return self::$current;
	}
	
	public static function GetString($file, $name, $subname = null) { //subname is optional
		if (!isset(self::$data[$file])) {
			if (!is_file(dirname(__FILE__).'/'.self::$current."/{$file}.json")) return null;
			self::$data[$file] = json_decode(file_get_contents(
				dirname(__FILE__).'/'.self::$current."/{$file}.json"), true);
		}
		if (!isset(self::$data[$file][$name])) return null;
		$block = self::$data[$file][$name];
		if ($subname !== null) {
			if (!isset($block[$subname])) return null;
			else return $block[$subname];
		}
		else return $block;
	}
	
	public static function InitLanguage() {
		if (isset($_COOKIE['Language'])) {
			$token = strval($_COOKIE['Language']);
			if (is_dir(dirname(__FILE__)."/{$token}")) {
				self::$current = $token;
				self::$data = array();
				return;
			}
		}
		self::$current = LANG_BACKUP;
		self::$data = array();
	}
}

Lang::InitLanguage();