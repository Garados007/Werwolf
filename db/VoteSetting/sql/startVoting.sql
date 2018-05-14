UPDATE <?php echo DB_PREFIX; ?>VoteSetting
	SET VoteStart = <?php echo $start; ?>
	WHERE Chat = <?php echo $chat; ?> AND VoteKey = '<?php echo $key; ?>';