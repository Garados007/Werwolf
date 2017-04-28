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

function execSql($file) {
	if ($result = DB::executeFormatFile($file, array())) {
		$result->executeAll();
		if (DB::getError() != null) {
			echo '<br/>Error while execution.<br/>Error:\''.DB::getError().'\'';
			return false;
		}
	}
	else {
		echo '<br/>Error while execution.<br/>Error:"'.DB::getError().'"';
		return false;
	}
	return true;
}

echo '<br/>Try to create tables if not exists';
if (!execSql(dirname(__FILE__).'/sql/createDatabase.sql')) return;

echo '<br/>Add data to '.DB_PREFIX.'ChatMode table';
if (!execSql(dirname(__FILE__).'/sql/putChatModeData.sql')) return;




echo '<br/>Checkup Finished. Everything is okay.';