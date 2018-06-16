SELECT RoleIndex INTO @ind
FROM <?php echo DB_PREFIX; ?>Roles 
WHERE Player = <?php echo $player; ?> AND
	RoleKey = '<?php echo $role; ?>';

UPDATE <?php echo DB_PREFIX; ?>Roles
SET RoleIndex = RoleIndex - 1
WHERE Player IN (
		SELECT Id
		FROM <?php echo DB_PREFIX; ?>Player
		WHERE Game = <?php echo $game; ?>
	) AND
	RoleKey = '<?php echo $role; ?>' AND
	RoleIndex > @ind;

DELETE FROM <?php echo DB_PREFIX; ?>VisibleRoles
WHERE Target=<?php echo $player; ?> AND
	RoleKey='<?php echo $role; ?>';

DELETE FROM <?php echo DB_PREFIX; ?>Roles
WHERE Player = <?php echo $player; ?> AND
	RoleKey = '<?php echo $role; ?>';