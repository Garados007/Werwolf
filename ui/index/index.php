<?php

include_once dirname(__FILE__).'/../../lang/Lang.php';

if (isset($_GET["set-lang"])) {
	Lang::SetLanguage($_GET["set-lang"]);
}

?>
<html>
<head>
	<meta charset="utf-8" />
	<title><?php echo Lang::GetString('ui-index', 'header-title'); ?></title>
	<link href="/<?php echo URI_PATH; ?>ui/css/index.css" rel="stylesheet" />
	<script src="/<?php echo URI_PATH; ?>ui/js/jquery-3.2.1.min.js"></script>
	<script src="/<?php echo URI_PATH; ?>ui/js/language.js"></script>
	<script src="/<?php echo URI_PATH; ?>ui/js/login-frame.js"></script>
	
	
	<script type="text/javascript">
		$WWV = {
			urlHost: "<?php echo URI_HOST; ?>",
			urlBase: "<?php echo URI_PATH; ?>"
		};
	</script>
</head>
<body>
	<div class="content-frame">
		<div class="image-box">
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
			<?php echo Lang::GetString('ui-index', 'content-title'); ?>
		</div>
		<div class="start-button">
			<?php echo Lang::GetString('ui-index', 'start-button'); ?>
		</div>
		<div class="footer">
		
		</div>
	</div>
	<div class="overlay">
		<div class="overlay-window">
			<div class="close-button">x</div>
			<iframe class="login-window"></iframe>
		</div>
	</div>
</body>
</html>