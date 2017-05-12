<?php

include_once dirname(__FILE__).'/../../config.php';

if (!MAINTENANCE) {
	header("Location: /".URI_PATH."ui/", true, 302);
	exit;
}

include_once dirname(__FILE__).'/../../lang/Lang.php';

if (isset($_GET["set-lang"])) {
	Lang::SetLanguage($_GET["set-lang"]);
}

?>
<!DOCTYPE html>
<html>
<head>
	<meta charset="utf-8" />
	<meta name="viewport" content="width=device-width, initial-scale=1.0">
	<title><?php echo Lang::GetString('ui-maintenance', 'header'); ?></title>
	<link href="/<?php echo URI_PATH; ?>ui/css/index.css" rel="stylesheet" />
	<script src="/<?php echo URI_PATH; ?>ui/js/jquery-3.2.1.min.js"></script>
	<script src="/<?php echo URI_PATH; ?>ui/js/language.js"></script>
	
	<script type="text/javascript">
		$(function() {
			var time = 30;
			var wait = function() {
				if (time > 0) {
					$(".time-left span").text(" "+time);
					time--;
					setTimeout(wait, 1000);
				}
				else document.location.reload();
			};
			wait();
		});
	</script>
</head>
<body>
	<div class="content-frame">
		<div class="image-box">
			<img src="/<?php echo URI_PATH; ?>ui/img/title.png"></img>
			<div class="language-selector">
				<div class="visible-block">
					<img class="lang-img" src="/<?php echo URI_PATH; ?>ui/img/lang/<?php echo strtolower(Lang::GetLanguage()); ?>.png"></img>
					<?php echo strtoupper(Lang::GetLanguage()); ?>
				</div>
				<div class="all-block">
<?php foreach (Lang::GetAllLanguages() as $lang) { ?>
					<a href="?set-lang=<?php echo $lang; ?>">
						<img class="lang-img" src="/<?php echo URI_PATH; ?>ui/img/lang/<?php echo strtolower($lang); ?>.png"></img>
						<?php echo strtoupper($lang); ?>
					</a>
<?php } ?>
				</div>
			</div>
		</div>
		<div class="content-title">
			<?php echo Lang::GetString('ui-maintenance', 'title'); ?>
		</div>
		<div class="time-left" style="text-align:center;font-size:1.4em;margin-bottom:2em;">
			<?php echo Lang::GetString('ui-maintenance', 'left'); ?>
			<span> 30</span>
		</div>
		<div class="footer">
		
		</div>
	</div>
</body>
</html>