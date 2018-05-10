INSERT INTO <?php echo DB_PREFIX; ?>Player
	(Game, User, Alive, ExtraWolfLive, Vars) VALUES
	(<?php echo $game; ?>, <?php echo $user; ?>, TRUE, 
		<?php echo $extraLive ? 'TRUE' : 'FALSE'; ?>, 
		<?php echo $vars === null ? "NULL" : "'".$vars."'"; ?>);
SELECT LAST_INSERT_ID() AS "Id";
