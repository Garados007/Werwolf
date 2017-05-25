<?php

header("Content-Type: application/manifest+json; charset=utf-8");

include dirname(__FILE__).'/../config.php';
include dirname(__FILE__).'/../lang/Lang.php';

if (isset($_GET["lang"])) {
	Lang::SetLanguage($_GET["lang"], false);
}

//Quelle: https://developer.mozilla.org/en-US/docs/Web/Manifest

?>
{
	"short_name": "<?php echo Lang::GetString("manifest-lang","short_name"); ?>",
	"name": "<?php echo Lang::GetString("manifest-lang","name"); ?>",
	"description": "<?php echo Lang::GetString("manifest-lang","description"); ?>",
	"dir": "<?php echo Lang::GetString("manifest-lang","dir"); ?>",
	"icons": [
	],
	"start_url": "/<?php echo URI_PATH; ?>ui/index/?webapp=true",
	"background_color": "#242424",
	"theme_color": "#242424",
	"display": "fullscreen",
	"related_applications": [{
		"plattform": "web"
	}],
	"lang": "<?php echo Lang::GetLanguage(); ?>",
	"orientation": "any"
}