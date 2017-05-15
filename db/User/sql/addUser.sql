INSERT INTO <?php echo DB_PREFIX; ?>User
	(GroupId, UserId, LastOnline) VALUES
	(<?php echo $group; ?>, <?php echo $user; ?>, 0);