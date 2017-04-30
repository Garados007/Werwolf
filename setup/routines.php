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

function importPhp($dir) {
	$it = new RecursiveIteratorIterator(new RecursiveDirectoryIterator($dir));
	$it->rewind();
	while ($it->valid()) {
		if (!$it->isDot() && $it->isFile() &&$it->getExtension() == 'php')
			include_once $it->getPathname();
		$it->next();
	}
}

echo 'Try to create tables if not exists';
if (!execSql(dirname(__FILE__).'/sql/createDatabase.sql')) return;

echo '<br/>Add data to '.DB_PREFIX.'ChatMode table';
if (!execSql(dirname(__FILE__).'/sql/putChatModeData.sql')) return;

echo '<br/>Add data to '.DB_PREFIX.'Phases table';
if (!execSql(dirname(__FILE__).'/sql/putPhases.sql')) return;

echo '<br/>Try to include DB files for syntax check';
importPhp(dirname(__FILE__).'/../db');
echo '<br/>All Files are okay.';

echo '<br/>Try to include Logic files for syntax check';
importPhp(dirname(__FILE__).'/../logic');
echo '<br/>All Files are okay.';
			
echo '<br/>Checkup Finished. Everything is okay.';