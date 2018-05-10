DELETE FROM <?php echo DB_PREFIX; ?>Votes
	WHERE Setting = <?php echo $chat; ?>,
		VoteKey = <?php echo $key; ?>;
	
DELETE FROM <?php echo DB_PREFIX; ?>VoteSetting
	WHERE Chat = <?php echo $chat; ?>,
		VoteKey = <?php echo $key; ?>;