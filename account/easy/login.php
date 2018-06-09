<?php

include_once dirname(__FILE__).'/../../config.php';
include_once dirname(__FILE__).'/../../db/db.php';

if (RELEASE_MODE) {
	//Dont use it on a live system !!!
	http_response_code(500); //Internal Server Error
	exit;
}

$data = array();
if ($response = DB::executeFormatFile(dirname(__FILE__).'/selectAll.sql', array())) {
	$set = $response->getResult();
	while ($entry = $set->getEntry()) {
		$data[intval($entry["Id"])] = strval($entry["Name"]);
	}
}

session_start();

if (isset($_POST["login"]) && isset($_POST["user"])) {
	$_SESSION["Id"] = intval($_POST["user"]);
	$_SESSION["Name"] = $data[$_SESSION["Id"]];
	$_SESSION["Email"] = $_SESSION["Name"] . '@testuser';
	header("Location: /".URI_PATH."account/checked/");
	exit;
}

if (isset($_POST["create"]) && isset($_POST["newuser"])) {
	$response = DB::executeFormatFile(dirname(__FILE__).'/insert.sql', array(
		"name" => DB::escape(strval($_POST["newuser"]))
	));
	echo DB::getError();
	if ($set = $response->getResult()) $set->free();
	$entry = $response->getResult()->getEntry();
	$_SESSION["Id"] = intval($entry["Id"]);
	$_SESSION["Name"] = strval($_POST["newuser"]);
	$_SESSION["Email"] = $_SESSION["Name"] . '@testuser';
	header("Location: /".URI_PATH."account/checked/");
	exit;
}

?>
<html>
<head>
	<meta charset="utf-8" />
	<title>Login</title>
</head>
<body>
	<form method="post">
		<fieldset>
			<legend>All User:</legend>
			<select name="user">
<?php foreach ($data as $key => $value) {?>
				<option value="<?php echo $key; ?>"><?php echo $value; ?></option>
<?php } ?>
			</select>
			<input type="submit" name="login" value="Login" />
		</fieldset>
		<fieldset>
			<legend>New User:</legend>
			<input name="newuser" type="text"/>
			<input type="submit" name="create" value="Create" />
		</fieldset>
	</form>
</body>
</html>