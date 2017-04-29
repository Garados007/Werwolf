<?php

//include_once dirname(__FILE__).'/../config.php';

class DB {
	private static $connection = null;
	
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
	
	public static function getResult($sql) { //DBResult
		if (self::$connection !== null) self::connect();
		return new DBResult(self::$connection->query($sql));
	}
	
	public static function getMultiResult($sql) { //DBMultiResult
		if (self::$connection !== null) self::connect();
		$result = self::$connection->multi_query($sql);
		if ($result === false) return false;
		return new DBMultiResult(self::$connection);
	}
	
	public static function executeFile($path) { //DBMultiResult
		if (!file_exists($path)) return false;
		else return self::getMultiResult(file_get_contents($path));
	}
	
	public static function executeFormatFile($path, $data) {
		// echo ".";
		if (!file_exists($path)) return false;
		// echo ".";
		extract ($data);
		ob_start();
		$success = true;
		include $path;
		$sql = ob_get_contents();
		ob_end_clean();
		if ($success === false) return false;
		return self::getMultiResult($sql);
	}
	
	public static function getError() {
		return self::$connection->error;
	}
	
	public static function escape($text) {
		return addslashes(self::$connection->real_escape_string($text), '%_');
	}
}

class DBMultiResult {
	private $connection;
	
	public function __construct($connection) {
		$this->connection = $connection;
	}
	
	public function getResult() {
		if (!$this->hasMoreResults()) return false;
		$result = new DBResult($this->connection->store_result());
		$this->connection->next_result();
		return $result;
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
	}
	
	public function executeAll() {
		do {
			if ($result = $this->connection->store_result())
				$result->free();
			$this->connection->more_results();
		}
		while ($this->connection->next_result());
	}
}

class DBResult {
	private $result;
	
	public function __construct($result) {
		$this->result = $result;
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
		$this->result->free();
	}
}