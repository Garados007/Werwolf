SELECT ChatMode, SupportedRoleKey, EnableWrite, Visible
FROM <?php echo DB_PREFIX; ?>ChatModes
WHERE ChatMode = '<?php echo $chat; ?>' AND 
	SupportedRoleKey = '<?php echo $role; ?>';