<?php

include_once dirname(__FILE__).'/api.php';

$param = array();
if (isset($_GET["mode"])) $param["mode"] = $_GET["mode"];
if (isset($_GET["user"])) $param["user"] = $_GET["user"];
if (isset($_GET["name"])) $param["name"] = str_replace('+', ' ', $_GET["name"]);
if (isset($_GET["group"])) $param["group"] = $_GET["group"];
if (isset($_GET["roles"])) $param["roles"] = explode(',',$_GET["roles"]);
if (isset($_GET["game"])) $param["game"] = $_GET["game"];


foreach ($_POST as $key => $value)
	$param[$key] = $value;

header("Content-Type: application/json");
$api = new Api($param);
echo $api->exportResult();