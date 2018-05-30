<?php

if (count(get_included_files()) != 1) return; //test suite

if (!isset($_GET["_class"]) || !isset($_GET["_method"])) {
    http_response_code(403);
    return;
}

include_once __DIR__.'/../config.php';
if (MAINTENANCE) {
    include_once __DIR__ . '/Maintenance.php';
    $m = new Maintenance();
    echo json_encode($m->doMaintenance(), JSON_PRETTY_PRINT);
    return;
}

$class = null;

switch ($_GET["_class"]) {
    case "get": 
        include_once __DIR__ . '/GetApi.php';
        $class = new GetApi(); 
        break;
    case "conv":
        include_once __DIR__ . '/ConvApi.php';
        $class = new ConvApi();
        break;
    case "control":
        include_once __DIR__ . '/ControlApi.php';
        $class = new ControlApi();
        break;
    case "info":
        include_once __DIR__ . '/InfoApi.php';
        $class = new InfoApi();
        break;
    case "multi":
        include_once __DIR__ . '/MultiApi.php';
        $class = new MultiApi();
        break;
}

if ($class === null || !is_callable([$class, $_GET["_method"]]) || substr($_GET["_method"], 0, 1) == '_') {
    http_response_code(403); 
    return;
}

$method = $_GET["_method"];
$result = $class->$method();
echo json_encode($result, JSON_PRETTY_PRINT);
