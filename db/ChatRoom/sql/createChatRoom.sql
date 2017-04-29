INSERT INTO <?php echo DB_PREFIX; ?>Chats
	(Game, ChatMode, Opened) VALUES
	(<?php echo $game; ?>, '<?php echo $mode; ?>', FALSE);

SELECT LAST_INSERTED_ID() AS "Id";