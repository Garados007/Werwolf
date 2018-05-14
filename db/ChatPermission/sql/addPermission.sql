REPLACE INTO <?php echo DB_PREFIX; ?>ChatPermission
	(Room, RoleKey, PEnable, PWrite, PVisible) VALUES 
	(<?php echo $room; ?>, '<?php echo $role; ?>', 
		<?php echo $enable ? 'TRUE' : 'FALSE'; ?>,
		<?php echo $write ? 'TRUE' : 'FALSE'; ?>,
		<?php echo $visible ? 'TRUE' : 'FALSE'; ?>);