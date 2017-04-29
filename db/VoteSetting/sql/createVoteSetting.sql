INSERT INTO <?php echo DB_PREFIX; ?>VoteSetting
	(Chat, VoteStart, VoteEnd, ResultTarget) VALUES
	(<?php echo $chat; ?>, <?php echo $start; ?>, 
		<?php echo $end === null ? 'NULL' : $end; ?>, NULL);