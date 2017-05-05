<?php

include_once dirname(__FILE__).'/../../account/manager.php';

$user = AccountManager::GetCurrentAccountData();
if (!$user["login"]) {
	header("Location: /".URI_PATH."ui/", true, 302);
	exit;
}

include_once dirname(__FILE__).'/../../lang/Lang.php';

if (isset($_GET["set-lang"])) {
	Lang::SetLanguage($_GET["set-lang"]);
}

?>
<html>
<head>
	<meta charset="utf-8" />
	<meta name="viewport" content="width=device-width, initial-scale=1.0">
	<title><?php echo Lang::GetString('ui-game-index', 'header-title'); ?></title>
	<link href="/<?php echo URI_PATH; ?>ui/css/loadingbox.css" rel="stylesheet" />
	<link href="/<?php echo URI_PATH; ?>ui/css/game.css" rel="stylesheet" />
	<script src="/<?php echo URI_PATH; ?>ui/js/language-texts.js.php"></script>
	<script src="/<?php echo URI_PATH; ?>ui/js/jquery-3.2.1.min.js"></script>
	<script src="/<?php echo URI_PATH; ?>ui/js/toolkit.js"></script>
	<script src="/<?php echo URI_PATH; ?>ui/js/toolkit.view.js"></script>
	<script src="/<?php echo URI_PATH; ?>ui/js/ui.js"></script>
	<script src="/<?php echo URI_PATH; ?>ui/js/game.js"></script>
	<script src="/<?php echo URI_PATH; ?>ui/js/classes.js"></script>
	
	<script type="text/javascript">
		$WWV = {
			urlHost: "<?php echo URI_HOST; ?>",
			urlBase: "<?php echo URI_PATH; ?>"
		};
	</script>
</head>
<body>
	<div class="loading-box">
		<div></div>
		<div>
			<div></div>
			<div class="loading-cell">
				<div class="loading-rotator">
					<div></div> <div></div> <div></div>
					<div></div> <div></div> <div></div>
					<div></div> <div></div> <div></div>
					<div></div> <div></div> <div></div>
				</div>
				<div class="loading-description">
					<?php echo Lang::GetString('ui-game-index', 'loading-data'); ?>
				</div>
			</div>
			<div></div>
		</div>
		<div></div>
	</div>
	<div class="main-window">
		<div>
			<div class="top-bar">
				<div>
					<div class="user-change-button" title="<?php echo Lang::GetString('ui-game-index', 'player-list-icon'); ?>">
						<img src="/<?php echo URI_PATH; ?>ui/img/Users-Group-icon.png"></img>
					</div>
					<div class="tab-list">
						<div class="tab-container">
						</div>
					</div>
					<div class="game-options" title="<?php echo Lang::GetString('ui-game-index', 'options-icon'); ?>">
						<img src="/<?php echo URI_PATH; ?>ui/img/Very-Basic-Menu-icon.png"></img>
					</div>
				</div>
			</div>
		</div>
		<div>
			<div class="main-content">
			
			</div>
		</div>	
	</div>
</body>
</html>