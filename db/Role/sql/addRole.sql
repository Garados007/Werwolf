SELECT COUNT(User) INTO @ind
FROM <?php echo DB_PREFIX; ?>Roles 
WHERE Game = <?php echo $game; ?> AND
	RoleKey = '<?php echo $role; ?>';
	
INSERT INTO <?php echo DB_PREFIX; ?>Roles
	(Game, User, RoleKey, RoleIndex) VALUES
	(<?php echo $game; ?>, <?php echo $user; ?>, '<?php echo $role; ?>', @ind+1);
	
SELECT @ind AS "RoleIndex";