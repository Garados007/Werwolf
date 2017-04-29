INSERT INTO <?php echo DB_PREFIX; ?>Player
	(Game, User, Alive, ExtraWolfLive) VALUES
	(<?php echo $game; ?>, <?php echo $user; ?>, TRUE, 
		<?php echo $extraLive ? 'TRUE' : 'FALSE'; ?>);
	