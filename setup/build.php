<?php

if (!isset($argc)) $argc = 0;
$console = $argc == 3 && $argv[2] == '-cmd';
define ('CT', $console ? PHP_EOL : '<br/>');

include_once __DIR__.'/../config.php';
include_once __DIR__.'/../ui/module/ModuleWorker.php';

//check config
if ($console && MANUAL_BUILD) {
    echo 'Manual build activated!'.CT.
        'You cannot run this command in the manual build mode. Change the config.php and try it again!';
    echo CT.CT.'If you want to see the manual build instructions, open the following url in your browser:';
    echo CT."\t".URI_HOST.URI_PATH.'setup'.CT;
    exit;
}

//Build elm config
$elm_build = true;
echo CT.'create config.elm for ui script';
include __DIR__ . '/../ui/elm/config.elm.php';

//Build Elm
$cwd = getcwd();
chdir(realpath(__DIR__ . '/..'));
if (!is_dir(dirname(__FILE__).'/../ui/game'))
    mkdir(dirname(__FILE__).'/../ui/game', 0777, true);
if (!is_dir(dirname(__FILE__).'/../ui/roles'))
	mkdir(dirname(__FILE__).'/../ui/roles', 0777, true);
if (MANUAL_BUILD) {
    $codestyle = ' style="color:white;background-color:#333;display:block;margin:0.5em 0;padding:0.5em;"';
    $elmcom = function ($source, $target, $doc) {
        $codestyle = ' style="color:white;background-color:#333;display:block;margin:0.5em 0;padding:0.5em;"';
        return '<code'.$codestyle.'>elm make '.implode(DIRECTORY_SEPARATOR, $source).
            ' --output '.implode(DIRECTORY_SEPARATOR, $target).
            (RELEASE_MODE ? '' : ' --debug --docs '.implode(DIRECTORY_SEPARATOR, $doc)).
            '</code>';
    };
    echo CT.CT.'MANUAL BUILD ACTIVATED!';
    echo CT.'<div style="margin:1em;padding:1em;border:1px solid red;border-radius:0.5em;font-family:sans-serif;">';
    echo '<h3 style="color:red;">Manual build instruction</h3><ol>';
    echo '<li>goto project root <code'.$codestyle.'>cd "'.realpath(__DIR__ .'/../').'"</code></li>';
    echo '<li>run elm build commands '.
        $elmcom(['ui','elm','Game','App.elm'], ['ui','game','script.js'], ['ui','game','doc.index.json']).
        $elmcom(['ui','elm','Game','Pages','RoleDescription.elm'],['ui','roles','script.js'],['ui','roles','doc.index.json']).
        '</li>';
    echo '<li>run this build setup again</li>';
    echo '</ol><p>Alternativly you can run the normal build system on an alternative server and copy the target files manualy.</p>';
    echo '<code'.$codestyle.'>php setup'.DIRECTORY_SEPARATOR.'build.php</code>';
    echo '</div>'.CT;
}
else {
    $run = function ($method, $desc) {
        $output = array();
        $status = 0;
        echo $desc . ' ... ';
        exec($method, $output, $status);
        echo $status.CT;
        echo implode(CT,$output);
        echo CT;
    };
    $elmmake = function ($run, $source, $target, $doc) {
        $rp = function ($path) {
            return implode(DIRECTORY_SEPARATOR,explode('/',$path));
        };
        $run('elm make '.realpath(__DIR__.'/../'.$source).' --output '.$rp(__DIR__.'/../'.$target).
            (RELEASE_MODE ? '' : ' --debug --docs '.$rp(__DIR__.'/../'.$doc)).' 2>&1',
            CT.'build elm file '.$source.' to '.$target);
    };
    echo CT;
    $elmmake($run, 'ui/elm/Game/App.elm', 'ui/game/script.js', 'ui/game/doc.index.json');
    $elmmake($run, 'ui/elm/Game/Pages/RoleDescription.elm', 'ui/roles/script.js', 'ui/roles/doc.index.json');
}
chdir($cwd);

//default elm config
unset($elm_build);
echo CT.'create config.elm for ui script';
include __DIR__ . '/../ui/elm/config.elm.php';

//Build JS & CSS
echo CT.CT.'init the import files for the ui';
ModuleWorker::prepairAllConfigs();
echo CT.'all import files initialized'.CT;

//Copy target files
$copy = function ($source, $target) {
    if (!is_file($source)) {
        echo CT.'Source file '.$source.' is missing! Cannot proceed process.';
        exit;
    }
    if (!is_dir(dirname($target))) mkdir(dirname($target), 0777, true);
    if (copy($source, $target) !== true) {
        echo CT.'Cannot copy '.$source.' to '.$target.'!';
        exit;
    }
    echo CT.'File copied: '.$source.' --> '.$target;
};
$copy(__DIR__.'/../ui/module/cache/test-game.css.index.css', __DIR__.'/../ui/css/test-game.css');
$copy(__DIR__.'/../ui/module/cache/test-lobby.css.css', __DIR__.'/../ui/game/style.css');
$copy(__DIR__.'/../ui/module/cache/test-lobby.css.index.css', __DIR__.'/../ui/css/test-lobby.css');
$copy(__DIR__.'/../ui/module/cache/game.js', __DIR__.'/../ui/game/script.compressed.js');
$copy(__DIR__.'/../ui/module/cache/roles.js', __DIR__.'/../ui/roles/script.compressed.js');

echo CT;
//build index files
$index = function ($target, $title,$start) {
    $content = '<!DOCTYPE HTML>'.PHP_EOL.
        '<html><head><meta charset="UTF-8">'.'
        <meta name="viewport" content="width=device-width, '.
        'initial-scale=1.0 /"><title>'.$title.
        '</title><style>html,head,body { padding:0; margin:0; }'.
        'body { font-family: calibri, helvetica, arial, sans-serif; }</style>'.
        '<script type="text/javascript" src="'.URI_HOST.URI_PATH.$target.
        '/script.js"></script><link rel="stylesheet" '.
        'property="stylesheet" href="'.URI_HOST.URI_PATH.$target.
        '/style.css" /></head><body><div id="elm-node"/><script type="text/javascript">'.
        $start.'.init({node:document.getElementById("elm-node")})</script></body></html>';
    file_put_contents(__DIR__.'/../'.$target.'/index.php', $content);
    echo CT.'Index file /'.$target.'/index.php created';
};
$index('ui/game', 'Game Lobby','Elm.Game.Lobby.GameLobby');
$index('ui/roles', 'Roles Help', 'Elm.Game.Pages.RoleDescription');