<?php

include_once dirname(__FILE__).'/../config.php';

if (MAINTENANCE) {
	echo '{"success":false,"error":"maintenance","errorkey":null,"request":null,"maintenance":true}';
	exit;
}

include_once dirname(__FILE__).'/api.php';

$param = array();
if (isset($_GET["mode"])) $param["mode"] = $_GET["mode"];
if (isset($_GET["user"])) $param["user"] = $_GET["user"];
if (isset($_GET["name"])) $param["name"] = str_replace('+', ' ', $_GET["name"]);
if (isset($_GET["group"])) $param["group"] = $_GET["group"];
if (isset($_GET["roles"])) $param["roles"] = explode(',',$_GET["roles"]);
if (isset($_GET["game"])) $param["game"] = $_GET["game"];
if (isset($_GET["role"])) $param["role"] = $_GET["role"];
if (isset($_GET["cmode"])) $param["cmode"] = $_GET["cmode"];
if (isset($_GET["chat"])) $param["chat"] = $_GET["chat"];
if (isset($_GET["since"])) $param["since"] = $_GET["since"];
if (isset($_GET["target"])) $param["target"] = $_GET["target"];
if (isset($_GET["end"])) $param["end"] = $_GET["end"];
if (isset($_GET["text"])) $param["text"] = str_replace('+', ' ', $_GET["text"]);
if (isset($_GET["me"])) $param["me"] = $_GET["me"];


foreach ($_POST as $key => $value)
	$param[$key] = $value;

header("Content-Type: application/json");
$api = new Api($param);
echo $api->exportResult();