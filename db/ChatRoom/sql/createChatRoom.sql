INSERT INTO <?php echo DB_PREFIX; ?>Chats
	(Game, ChatMode, Opened, EnableVoting) VALUES
	(<?php echo $game; ?>, '<?php echo $mode; ?>', FALSE, FALSE);

SELECT LAST_INSERT_ID() AS "Id";