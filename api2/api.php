<?php

if (count(get_included_files()) != 1) return; //test suite

if (!isset($_GET["_class"]) || !isset($_GET["_method"])) {
    http_response_code(403);
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
}

if ($class === null || !is_callable([$class, $_GET["_method"]]) || substr($_GET["_method"], 0, 1) == '_') {
    http_response_code(403); 
    return;
}

$method = $_GET["_method"];
$result = $class->$method();
echo json_encode($result, JSON_PRETTY_PRINT);
