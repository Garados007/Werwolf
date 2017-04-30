DELETE FROM <?php echo DB_PREFIX; ?>User
WHERE GroupId = <?php echo $group; ?> AND
	UserId = <?php echo $user; ?>;