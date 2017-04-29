INSERT INTO <?php echo DB_PREFIX; ?>Groups
	(Name, Created, LastGame, Leader, CurrentGame) VALUES
	(<?php echo $name; ?>, <?php echo $time; ?>, <?php echo $time; ?>,
		<?php echo $user; ?>, NULL);

SELECT LAST_INSERTED_ID() AS "Id";