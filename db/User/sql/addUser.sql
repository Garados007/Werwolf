INSERT INTO <?php echo DB_PREFIX; ?>User
	(GroupId, UserId, Player) VALUES
	(<?php echo $group; ?>, <?php echo $user; ?>, NULL);