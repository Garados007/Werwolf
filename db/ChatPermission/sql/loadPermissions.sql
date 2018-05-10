SELECT Room, RoleKey, PEnable, PWrite, PVisible
FROM <?php echo DB_PREFIX; ?>ChatPermission
WHERE Room = <?php echo $room; ?>;