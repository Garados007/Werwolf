UPDATE <?php echo DB_PREFIX; ?>User
	SET Player = <?php echo $player == null ? 'NULL' : $player; ?>
	WHERE GroupId = <?php echo $group; ?> AND
		UserId = <?php echo $user; ?>;