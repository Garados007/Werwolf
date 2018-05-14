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

include dirname(__FILE__).'/migrate.php';

echo 'Try to create tables if not exists';
if (!execSql(dirname(__FILE__).'/sql/createDatabase.sql')) return;

if (DB_USE_TRIGGER) {
	echo '<br/>Try to create trigger if not exists';
	if (!execSql(dirname(__FILE__).'/sql/createTrigger.sql')) return;
}
else echo '<br/>DB Triggers are not activated and also not created';

/*
echo '<br/><br/>Add data to '.DB_PREFIX.'ChatMode table';
if (!execSql(dirname(__FILE__).'/sql/putChatModeData.sql')) return;

echo '<br/>Add data to '.DB_PREFIX.'Phases table';
if (!execSql(dirname(__FILE__).'/sql/putPhases.sql')) return;
*/

echo '<br/><br/>Try to include DB files for syntax check';
importPhp(dirname(__FILE__).'/../db');
echo '<br/>All Files are okay.';

echo '<br/>Try to include Logic files for syntax check';
importPhp(dirname(__FILE__).'/../logic');
echo '<br/>All Files are okay.';
			
echo '<br/><br/>Check account manager file';
if (!is_file(dirname(__FILE__).'/../account/manager.php')) {
	echo '<br/>/account/manager.php file does not exists. Please make a copy of /account/manager.raw.template.php';
	return;
}	
include_once dirname(__FILE__).'/../account/manager.php';

echo '<br/>setup account manager plugin';
AccountManager::InitSystem();
echo '<br/>account manager initialized';
			
/*
echo '<br/><br/>init the import files for the ui';
include_once dirname(__FILE__).'/../ui/module/ModuleWorker.php';
ModuleWorker::prepairAllConfigs();
echo '<br/>all import files initialized';
*/
			
echo '<br/><br/>Checkup Finished. Everything is okay.';