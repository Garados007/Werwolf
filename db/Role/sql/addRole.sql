SELECT COUNT(User) INTO @ind
FROM <?php echo DB_PREFIX; ?>Roles r
JOIN <?php echo DB_PREFIX; ?>Player p ON (r.Player = p.Id)
WHERE p.Game = <?php echo $game; ?> AND
	r.RoleKey = '<?php echo $role; ?>';
	
INSERT INTO <?php echo DB_PREFIX; ?>Roles
	(Player, RoleKey, RoleIndex) VALUES
	(<?php echo $player; ?>, '<?php echo $role; ?>', @ind+1);
	
SELECT @ind AS "RoleIndex";