INSERT INTO <?php echo DB_PREFIX; ?>Games
	(MainGroup, Started, Finished, CurrentPhase, CurrentDay, RuleSet, Vars) VALUES
	(<?php echo $mainGroup; ?>, <?php echo time(); ?>, NULL, '<?php 
	echo $phase; ?>', 0, '<?php echo $rules; ?>', <?php 
	echo $vars === null ? "NULL" : "'".$vars."'"; ?>);
SELECT LAST_INSERT_ID() AS "Id";