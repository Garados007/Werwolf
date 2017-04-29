SELECT RoleKey, RoleIndex
FROM <?php echo DB_PREFIX; ?>Roles 
WHERE Game = <?php echo $game; ?> AND
	User = <?php echo $user; ?>;