<?php

include_once dirname(__FILE__).'/../db.php';
include_once dirname(__FILE__).'/../JsonExport/JsonExport.php';

class ChatEntry extends JsonExport {
	//the reference to the chat
	public $chat;
	//the user who postet this text
	public $user;
	//the message of this text
	public $text;
	//the timestamp when this text was sended
	public $sendDate;
	
	public function __construct($chat, $user, $text, $sendDate) {
		$this->jsonNames = array('chat', 'user', 'text', 'sendDate');
		$this->chat = $chat;
		$this->user = $user;
		$this->text = $text;
		$this->sendDate = $sendDate;
	}
	
	public static function loadAllEntrys($chat, $minSendDate) {
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/loadAllEntrys.sql',
			array(
				"chat" => $chat,
				"minSendDate" => $minSendDate
			)
		);
		$list = array();
		$set = $result->getResult();
		while ($entry = $set->getEntry())
			$list[] = new ChatEntry($chat, $entry["User"], $entry["Message"],
				intval($entry["SendDate"]));
		$result->free();
		return $list;
	}
	
	public static function addEntry($chat, $user, $text) {
		$time = time();
		$result = DB::executeFormatFile(
			dirname(__FILE__).'/sql/addEntry.sql',
			array(
				"chat" => $chat,
				"user" => $user,
				"text" => DB::escape($text),
				"time" => $time
			)
		);
		$result->free();
		return new ChatEntry($chat, $user, $text, $time);
	}
}