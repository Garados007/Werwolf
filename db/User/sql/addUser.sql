INSERT INTO <?php echo DB_PREFIX; ?>User
	(GroupId, UserId) VALUES
	(<?php echo $group; ?>, <?php echo $user; ?>);