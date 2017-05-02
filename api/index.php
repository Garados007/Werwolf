<?php

include_once dirname(__FILE__).'/api.php';

$param = array();
if (isset($_GET["mode"])) $param["mode"] = $_GET["mode"];
if (isset($_GET["user"])) $param["user"] = $_GET["user"];
if (isset($_GET["name"])) $param["name"] = str_replace('+', ' ', $_GET["name"]);


foreach ($_POST as $key => $value)
	$param[$key] = $value;

header("Content-Type: application/json");
$api = new Api($param);
echo $api->exportResult();