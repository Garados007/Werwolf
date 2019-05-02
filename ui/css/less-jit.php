<?php

require_once '../../git_modules/lessphp/lessc.inc.php';

function microtime_float()
{
    list($usec, $sec) = explode(" ", microtime());
    return ((float)$usec + (float)$sec);
}

header('Content-Type: text/css');

echo '/* LESS Just in Time compiler '.PHP_EOL 
    .PHP_EOL 
    .'   using: https://github.com/leafo/lessphp'.PHP_EOL
    .'*/'.PHP_EOL;

$time_start = microtime_float();

if (!isset($_GET['css'])) {
    echo '/* less file not given */ '.PHP_EOL;
    return;
}
$file = __DIR__ . '/' . $_GET['css'];
if (!is_file($file)) {
    echo '/* less file not found '.PHP_EOL
        .PHP_EOL
        .'   file: '.$file.PHP_EOL 
        .'*/'.PHP_EOL;
    return;
}

$less = new lessc;

try {
    echo $less->compileFile($file);
}
catch (exception $e) {
    echo '/* fatal error: '.PHP_EOL
        .PHP_EOL
        .'   '.$e->getMessage().PHP_EOL
        .'*/'.PHP_EOL;
    return;
}

$time_end = microtime_float();
echo '/* script finished execution in '.($time_end-$time_start).' seconds'.PHP_EOL
    .'   '.date(DATE_RFC822).PHP_EOL 
    .'*/'.PHP_EOL;
