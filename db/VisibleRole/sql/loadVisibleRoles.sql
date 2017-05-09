SELECT Game, MainUser, TargetUser, RoleKey
FROM <?php echo DB_PREFIX; ?>VisibleRoles
WHERE Game = <?php echo $game; ?> AND
	MainUser = <?php echo $main; ?> AND
	TargetUser = <?php echo $target; ?>;