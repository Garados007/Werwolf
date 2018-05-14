SELECT Player, Target, RoleKey
FROM <?php echo DB_PREFIX; ?>VisibleRoles
WHERE Player = <?php echo $player; ?> AND
	Target = <?php echo $target; ?>;