<?php

include_once dirname(__FILE__).'/../config.php';

class DB {
	private static $connection = null;
	private static $lastResult = false;
	private static $logKey = null;
	
	public static function connect() {
		if (self::$connection !== null) return;
		include_once dirname(__FILE__).'/../config.php';
		self::$connection = new mysqli(DB_SERVER, DB_USER, DB_PW, DB_NAME);
	}
	
	public static function close() {
		if (self::$connection === null) return;
		self::$connection->close();
		self::$connection = null;
	}
	
	private static function clearStoredResults() {
		do {
			if ($res = self::$connection->store_result())
				$res->free();
		}
		while (self::$connection->more_results() && self::$connection->next_result());
	}
	
	public static function getResult($sql) { //DBResult
		if (self::$connection === null) self::connect();
		if (!is_bool(self::$lastResult) && !self::$lastResult->hasFreed)
			self::$lastResult->free();
		self::clearStoredResults();
		self::log('singleResult', $sql);
		return new DBResult(self::$connection, self::$connection->query($sql));
	}
	
	public static function getMultiResult($sql, $source=null) { //DBMultiResult
		if (self::$connection === null) self::connect();
		if (!is_bool(self::$lastResult) && !self::$lastResult->hasFreed)
			self::$lastResult->free();
		self::clearStoredResults();
		self::log($source == null ? 'multiResult' : $source, $sql);
		$result = self::$connection->multi_query($sql);
		if ($error = self::getError()) {
			echo $error;
			echo "<br/>".PHP_EOL;
			debug_print_backtrace();
			exit;
		}
		if (!$result) return false;
		return new DBMultiResult(self::$connection);
	}
	
	public static function executeFile($path) { //DBMultiResult
		if (!file_exists($path)) return false;
		else return self::getMultiResult(file_get_contents($path), $path);
	}
	
	public static function executeFormatFile($path, $data) {
		// echo ".";
		if (!file_exists($path)) {
			echo "file not found: $path<br/>".PHP_EOL;
			debug_print_backtrace();
			return false;
		} 
		// echo ".";
		extract ($data);
		ob_start();
		$success = true;
		include $path;
		$sql = ob_get_contents();
		ob_end_clean();
		if ($success === false) return false;
		return self::getMultiResult($sql, $path);
	}
	
	public static function getError() {
		if (self::$connection == null) return null;
		return self::$connection->error;
	}
	
	public static function escape($text) {
		if (self::$connection === null) self::connect();
		return str_replace(
			array('%','_'),
			array('\%','\_'),
			self::$connection->real_escape_string($text)
		);
	}

	private static function log($source, $sql) {
		if (!DB_LOG_QUERYS) return;
		if (self::$logKey === null)
			self::$logKey = time();
		$content = '-- '.str_repeat('-', 60).PHP_EOL;
		$content .= '-- Call at: '.date('Y-m-d H:i:s', time()).PHP_EOL;
		$content .= '-- Source: '.$source.PHP_EOL;
		$content .= '-- '.str_repeat('-', 60).PHP_EOL;
		$content .= PHP_EOL;
		$content .= $sql;
		$content .= PHP_EOL.PHP_EOL;
		if (!is_dir(__DIR__ . '/../logs/'))
			mkdir(__DIR__ . '/../logs/');
			if (!is_dir(__DIR__ . '/../logs/db/'))
				mkdir(__DIR__ . '/../logs/db/');
		file_put_contents(
			__DIR__ . '/../logs/db/'.self::$logKey.'.sql',
			$content,
			FILE_APPEND | LOCK_EX);
	}
}

class DBMultiResult {
	private $connection;
	private $currentResult;
	private $lastResult;
	public $hasFreed = false;
	
	public function __construct(&$connection) {
		$this->connection = &$connection;
		$this->currentResult = $this->connection->store_result();
		$this->lastResult = false;
	}
	
	public function getResult() {
		if (!is_bool($this->lastResult) && !$this->lastResult->hasFreed)
			$this->lastResult->free();
		$this->lastResult = $this->currentResult;
		if (is_bool($this->currentResult)) $result = $this->currentResult;
		else $result = new DBResult($this->connection, $this->currentResult);
		if ($this->hasMoreResults()) {
			$this->connection->next_result();
			$this->currentResult = $this->connection->store_result();
		}
		else $this->currentResult = false;
		return $result;
	}
	
	public function freeResult() {
		if ($result = $this->getResult())
			if ($result !== true)
				$result->free();
	}
	
	public function getAllResultsAsEntrys() {
		$result = array();
		while ($entry = $this->getResult())
			$result[] = $entry->getAllEntrys();
		return $result;		
	}
	
	public function hasMoreResults() {
		return $this->connection->more_results();
	}
	
	public function flush() {
		while ($this->connection->next_result()) {;}
		if (!is_bool($this->currentResult)) $this->currentResult->free();
		if (!is_bool($this->lastResult)) $this->lastResult->free();
		$this->hasFreed = true;		
	}
	
	public function free() {
		$this->flush(); //Alias for flush();
	}
	
	public function executeAll() {
		do {
			if ($result = $this->connection->store_result())
				$result->free();
			$this->connection->more_results();
		}
		while ($this->connection->next_result());
		if (!is_bool($this->currentResult)) $this->currentResult->free();
		if (!is_bool($this->lastResult)) $this->lastResult->free();
		$this->hasFreed = true;		
	}
}

class DBResult {
	private $result;
	private $connection;
	public $hasFreed = false;
	
	public function __construct(&$connection, $result) {
		$this->result = $result;
		$this->connection = &$connection;
	}
	
	public function getEntry() {
		if ($this->result === false) return false;
		if ($this->result === true) return true;
		return $this->result->fetch_array(MYSQLI_ASSOC);
	}
	
	public function getAllEntrys() {
		$result = array();
		while ($entry = $this->getEntry()) $result[] = $entry;
		return $result;
	}
	
	public function free() {
		if ($this->result && $this->result !== true) {
			$this->result->free();
			$this->result->close();
		}
		$this->hasFreed = true;
	}
}

function intvaln($value) {
	if ($value === null)
		return null;
	else return intval($value);
}