INSERT INTO <?php echo DB_PREFIX; ?>Groups
	(Name, Created, LastGame, Leader, CurrentGame, EnterKey) VALUES
	('<?php echo $name; ?>', <?php echo $time; ?>, <?php echo $time; ?>,
		<?php echo $user; ?>, NULL, '<?php echo $key; ?>');

SELECT LAST_INSERT_ID() AS "Id";