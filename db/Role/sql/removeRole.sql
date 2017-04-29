SELECT RoleIndex INTO @ind
FROM <?php echo DB_PREFIX; ?>Roles 
WHERE Game = <?php echo $game; ?> AND
	User = <?php echo $user; ?> AND
	RoleKey = '<?php echo $role; ?>';

UPDATE <?php echo DB_PREFIX; ?>Roles
SET RoleIndex = RoleIndex - 1
WHERE Game = <?php echo $game; ?> AND
	RoleKey = '<?php echo $role; ?>' AND
	RoleIndex > @ind;

DELETE FROM <?php echo DB_PREFIX; ?>Roles
WHERE Game = <?php echo $game; ?> AND
	User = <?php echo $user; ?> AND
	RoleKey = '<?php echo $role; ?>';