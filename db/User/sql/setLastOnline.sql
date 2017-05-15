UPDATE <?php echo DB_PREFIX; ?>User
	SET LastOnline = <?php echo $time; ?>
	WHERE GroupId = <?php echo $group; ?> AND
		UserId = <?php echo $user; ?>;