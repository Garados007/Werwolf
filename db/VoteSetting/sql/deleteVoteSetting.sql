DELETE FROM <?php echo DB_PREFIX; ?>Votes
	WHERE Setting = <?php echo $chat; ?>;
	
DELETE FROM <?php echo DB_PREFIX; ?>VoteSetting
	WHERE Chat = <?php echo $chat; ?>;