INSERT INTO <?php echo DB_PREFIX; ?>Chats
	(Game, ChatMode, Opened) VALUES
	(<?php echo $game; ?>, '<?php echo $mode; ?>', FALSE);

SELECT LAST_INSERT_ID() AS "Id";