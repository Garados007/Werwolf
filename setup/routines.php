<?php

if (!file_exists(dirname(__FILE__).'/../config.php')) {
	echo 'config.php doesn\'t exists. Please make a copy of config.template.php!';
	return;
}

include_once dirname(__FILE__).'/../config.php';

if (RELEASE_MODE) {
	echo 'System is in release mode. No changes are done. The check abort now.';
	return;
}

include dirname(__FILE__).'/../db/db.php';

try {
	DB::connect();
}
catch (Exception $ex) {
	echo 'Cannot connect to database<br/>';
	echo "Exception: {$ex}";
	return;
}

echo '<br/>Try to create tables if not exists';
if ($result = DB::executeFormatFile(dirname(__FILE__).'/sql/createDatabase.sql', array())) {
	$result->executeAll();
	if (DB::getError() != null) {
		echo '<br/>Error while execution.<br/>Error:\''.DB::getError().'\'';
		return;
	}
}
else {
	echo '<br/>Error while execution.<br/>Error:"'.DB::getError().'"';
	return;
}




echo '<br/>Checkup Finished. Everything is okay.';