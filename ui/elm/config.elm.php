<?php

include_once __DIR__ . '/../../config.php';

$v = json_decode(file_get_contents(__DIR__ .'/../../setup/versions.json'), true);
$v = $v[count($v) - 1];

ob_start();

?>
module Config exposing (..)

uri_host : String
uri_host = "<?php echo URI_HOST; ?>"

uri_path : String
uri_path = "<?php echo URI_PATH; ?>"

lang_backup : String
lang_backup = "<?php echo LANG_BACKUP; ?>"

build_year : Int
build_year = <?php echo date("Y"); ?>


build_version : String
build_version = "<?php echo $v; ?>"

run_build : Bool
run_build = <?php echo isset($elm_build) && $elm_build ? 'True' : 'False' ; ?>

<?php

$content = ob_get_clean();
file_put_contents (__DIR__ . '/config.elm', $content);
