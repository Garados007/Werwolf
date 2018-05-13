UPDATE <?php echo DB_PREFIX; ?>VoteSetting
	SET VoteEnd = <?php echo $end; ?>, 
		ResultTarget = <?php echo $result == null ? 'NULL' : $result; ?>
	WHERE Chat = <?php echo $chat; ?> AND VoteKey = '<?php echo $key; ?>';