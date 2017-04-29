INSERT INTO <?php echo DB_PREFIX; ?>Games
	(MainGroup, Started, Finished, CurrentPhase) VALUES
	(<?php echo $mainGroup; ?>, <?php echo time(); ?>, NULL, 'mainstor');
SELECT LAST_INSERT_ID() AS "Id";