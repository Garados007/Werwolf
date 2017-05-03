<?php

//if you have implemented your functions, just copy it to 'manager.php'

include_once dirname(__FILE__).'/../config.php';

class AccountManager {
	//this function is called, when the UI opens the login window
	//redirect to your page
	public static function ShowLoginWindow() {
		//implement your function here
	}
	//this function is called, when the UI opens the logout window
	//redirect to your page
	public static function ShowLogoutWindow() {
		//implement your function here
	}
	//this function must be called, when the Login successed
	//check if the data is valid and return a json object
	public static function AccountChecked() {
		//implement your function here
		
		$valid = false;
		
		
		if ($valid) {
			header("Content-Type: application/json");
			echo self::GetCurrentAccountData();
		}
	}
	//returns the current user data as a array
	public static function GetCurrentAccountData() {
		//implement your function here
		//this code is just a sample
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
		//implement your function here
	}
	//this function is called, when the backend needs to check if a user name exists
	public static function ExistsAccountName($name) {
		//implement your function here
	}
	//this function is called, when the backend needs the user name
	public static function GetAccountName($id) {
		//implement your function here
	}
	//this function is called, when the setup runs and want to configure this module
	public static function InitSystem() {
		//implement your function here
	}
}