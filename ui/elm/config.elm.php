<?php

include_once __DIR__ . '/../../config.php';

ob_start();

?>
module Config exposing (..)

uri_host : String
uri_host = "<?php echo URI_HOST; ?>"

uri_path : String
uri_path = "<?php echo URI_PATH; ?>"

lang_backup : String
lang_backup = "<?php echo LANG_BACKUP; ?>"

<?php

$content = ob_get_clean();
file_put_contents (__DIR__ . '/config.elm', $content);
