INSERT INTO <?php echo DB_PREFIX; ?>Player
	(Game, User, Alive, ExtraWolfLive, SpecialVoting) VALUES
	(<?php echo $game; ?>, <?php echo $user; ?>, TRUE, 
		<?php echo $extraLive ? 'TRUE' : 'FALSE'; ?>, 0);
	