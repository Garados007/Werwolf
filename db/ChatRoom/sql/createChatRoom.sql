INSERT INTO <?php echo DB_PREFIX; ?>Chats
	(Game, ChatRoom) VALUES
	(<?php echo $game; ?>, '<?php echo $mode; ?>');

SELECT LAST_INSERT_ID() AS "Id";