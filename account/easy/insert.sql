REPLACE INTO <?php echo DB_PREFIX; ?>Accounts(Name)
	VALUES ('<?php echo $name; ?>');
SELECT LAST_INSERT_ID() AS "Id";