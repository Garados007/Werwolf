INSERT INTO <?php echo DB_PREFIX; ?>Games
	(MainGroup, Started, Finished, CurrentPhase, CurrentLevel) VALUES
	(<?php echo $mainGroup; ?>, <?php echo time(); ?>, NULL, 'mainstor', 0);
SELECT LAST_INSERT_ID() AS "Id";