<?php

if (!is_file(dirname(__FILE__).'/manager.php')) {
	http_response_code(501); //Not implemented
	exit;
}

include_once dirname(__FILE__).'/manager.php';

if (!isset($_GET["page"])) {
	http_response_code(404);
	exit;
}

switch ($_GET["page"]) {
	case "login": AccountManager::ShowLoginWindow(); break;
	case "logout": AccountManager::ShowLogoutWindow(); break;
	case "checked": AccountManager::AccountChecked(); break;
	default: http_response_code(404); break;
}