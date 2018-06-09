<?php
//This is a template config file
//To get your version, just copy this file to 'config.php' and do your settings.


//Database
define('DB_SERVER', 'localhost');
define('DB_USER', 'root');
define('DB_PW', '');
define('DB_NAME', 'werwolf');
define('DB_PREFIX', 'werwolf_'); //The prefix for the tables. leave it blank for no prefix.
define('DB_USE_TRIGGER', true); //Use sql trigger to clear the tables
define('DB_LOG_QUERYS', false);  //for debug mode - logs all querys to a log file


//Runtime Setting
define('RELEASE_MODE', false);
define('MAINTENANCE', false);

//Server Setting
define('URI_HOST', 'http://localhost/');
define('URI_PATH', 'werwolf/'); //if you leave this blank, then the root of the webspace is the root of this project
define('MANUAL_BUILD', false); //false-server build it own files, true-manual build of files

//Language Setting
define('LANG_BACKUP', 'de'); //this is the backup language when none is setted
