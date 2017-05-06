<?php

//this is a template for testing purpose. Don't use it on a live system.

include_once dirname(__FILE__).'/../config.php';

if (RELEASE_MODE) {
	//Dont use it on a live system !!!
	http_response_code(500); //Internal Server Error
	exit;
}

include_once dirname(__FILE__).'/../db/db.php';

class AccountManager {
	//this function is called, when the UI opens the login window
	public static function ShowLoginWindow() {
		header("Location: /".URI_PATH."account/easy/login.php");
	}
	//this function is called, when the UI opens the logout window
	public static function ShowLogoutWindow() {
		header("Location: /".URI_PATH."account/easy/logout.php");
	}
	//this function must be called, when the Login successed
	//check if the data is valid and return a json object
	public static function AccountChecked() {
		header("Content-Type: application/json");
		echo json_encode(self::GetCurrentAccountData());
	}
	//returns the current user data as a array
	public static function GetCurrentAccountData() {
		session_start();
		if (isset($_SESSION["Id"]))
			$data = array(
				"login" => true, //the user is logged in
				"id" => $_SESSION["Id"], //account id
				"name" => $_SESSION["Name"] //user name
			);
		else $data = array(
				"login" => false //the user is not logged in
			);
		return $data; //important: The structure of this object must be same as here
	}
	//this function is called, when the backend needs to check if an id exists
	public static function ExistsAccountId($id) {
		if ($reponse = DB::executeFormatFile(dirname(__FILE__).'/easy/selectAll.sql', array())) {
			$set = $response->getResult();
			while ($entry = $set->getEntry()) {
				if ($entry["Id"] == $id) return true;
			}
		}
		return false;
	}
	//this function is called, when the backend needs to check if a user name exists
	public static function ExistsAccountName($name) {
		if ($reponse = DB::executeFormatFile(dirname(__FILE__).'/easy/selectAll.sql', array())) {
			$set = $response->getResult();
			while ($entry = $set->getEntry()) {
				if ($entry["Name"] == $name) return true;
			}
		}
		return false;
	}
	//this function is called, when the backend needs the user name
	public static function GetAccountName($id) {
		if ($response = DB::executeFormatFile(dirname(__FILE__).'/easy/selectAll.sql', array())) {
			$set = $response->getResult();
			while ($entry = $set->getEntry()) {
				if ($entry["Id"] == $id) return $entry["Name"];
			}
		}
	}
	//this function is called, when the setup runs and want to configure this module
	public static function InitSystem() {
		DB::executeFormatFile(dirname(__FILE__).'/easy/createTables.sql', array())->free();
	}
}