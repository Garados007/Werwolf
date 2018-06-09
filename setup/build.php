<?php

include_once __DIR__.'/../config.php';
include_once __DIR__.'/../ui/module/ModuleWorker.php';

//Build elm config
$elm_build = true;
echo '<br/>create config.elm for ui script';
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
            ' --yes --output '.implode(DIRECTORY_SEPARATOR, $target).
            (RELEASE_MODE ? '' : ' --debug --docs '.implode(DIRECTORY_SEPARATOR, $doc)).
            '</code>';
    };
    echo '<br/><br/>MANUAL BUILD ACTIVATED!';
    echo '<br/><div style="margin:1em;padding:1em;border:1px solid red;border-radius:0.5em;font-family:sans-serif;">';
    echo '<h3 style="color:red;">Manual build instruction</h3><ol>';
    echo '<li>goto project root <code'.$codestyle.'>cd "'.realpath(__DIR__ .'/../').'"</code></li>';
    echo '<li>run elm build commands '.
        $elmcom(['ui','elm','Game','Lobby','GameLobby.elm'], ['ui','game','script.js'], ['ui','game','doc.index.json']).
        $elmcom(['ui','elm','Game','Pages','RoleDescription.elm'],['ui','roles','script.js'],['ui','roles','doc.index.json']).
        '</li>';
    echo '</ol><p>Alternativly you can run the normal build system on an alternative server and copy the target files manualy.</p>';
    echo '<code'.$codestyle.'>php setup'.DIRECTORY_SEPARATOR.'build.php</code>';
    echo '</div><br/>';
}
else {
    $run = function ($method, $desc) {
        $output = array();
        $status = 0;
        echo $desc . ' ... ';
        exec($method, $output, $status);
        echo $status.'<br/>';
        echo implode('<br/>',$output);
        echo '<br/>';
    };
    $elmmake = function ($run, $source, $target, $doc) {
        $rp = function ($path) {
            return implode(DIRECTORY_SEPARATOR,explode('/',$path));
        };
        $run('elm make '.realpath(__DIR__.'/../'.$source).' --yes --output '.$rp(__DIR__.'/../'.$target).
            (RELEASE_MODE ? '' : ' --debug --docs '.$rp(__DIR__.'/../'.$doc)).' 2>&1',
            '</br>build elm file '.$source.' to '.$target);
    };
    echo '<br/>';
    $elmmake($run, 'ui/elm/Game/Lobby/GameLobby.elm', 'ui/game/script.js', 'ui/game/doc.index.json');
    $elmmake($run, 'ui/elm/Game/Pages/RoleDescription.elm', 'ui/roles/script.js', 'ui/roles/doc.index.json');
}
chdir($cwd);

//default elm config
unset($elm_build);
echo '<br/>create config.elm for ui script';
include __DIR__ . '/../ui/elm/config.elm.php';

//Build JS & CSS
echo '<br/><br/>init the import files for the ui';
ModuleWorker::prepairAllConfigs();
echo '<br/>all import files initialized</br>';

//Copy target files
$copy = function ($source, $target) {
    if (!is_file($source)) {
        echo '<br/>Source file '.$source.' is missing! Cannot proceed process.';
        exit;
    }
    if (!is_dir(dirname($target))) mkdir(dirname($target), 0777, true);
    if (copy($source, $target) !== true) {
        echo '<br/>Cannot copy '.$source.' to '.$target.'!';
        exit;
    }
    echo '<br/>File copied: '.$source.' --> '.$target;
};
$copy(__DIR__.'/../ui/module/cache/test-game.css.index.css', __DIR__.'/../ui/css/test-game.css');
$copy(__DIR__.'/../ui/module/cache/test-lobby.css.css', __DIR__.'/../ui/game/style.css');
$copy(__DIR__.'/../ui/module/cache/test-lobby.css.index.css', __DIR__.'/../ui/css/test-lobby.css');
$copy(__DIR__.'/../ui/module/cache/game.js', __DIR__.'/../ui/game/script.compressed.js');
$copy(__DIR__.'/../ui/module/cache/roles.js', __DIR__.'/../ui/roles/script.compressed.js');

echo '<br/>';
//build index files
$index = function ($target, $title) {
    $content = '<!DOCTYPE HTML>'.PHP_EOL.
        '<html><head><meta charset="UTF-8"><title>'.$title.
        '</title><style>html,head,body { padding:0; margin:0; }'.
        'body { font-family: calibri, helvetica, arial, sans-serif; }</style>'.
        '<script type="text/javascript" src="'.URI_HOST.URI_PATH.$target.
        '/script.js"></script><link rel="stylesheet" '.
        'property="stylesheet" href="'.URI_HOST.URI_PATH.$target.
        '/style.css" /></head><body><script type="text/javascript">'.
        'Elm.Game.Lobby.GameLobby.fullscreen()</script></body></html>';
    file_put_contents(__DIR__.'/../'.$target.'/index.php', $content);
    echo '<br/>Index file /'.$target.'/index.php created';
};
$index('ui/game', 'Game Lobby');
$index('ui/roles', 'Roles Help');