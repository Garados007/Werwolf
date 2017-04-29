UPDATE <?php echo DB_PREFIX; ?>VoteSetting
	SET VoteEnd = <?php echo $end; ?>, ResultTarget = <?php echo $result; ?>
	WHERE Chat = <?php echo $chat; ?>;