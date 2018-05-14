SELECT RoleKey, RoleIndex
FROM <?php echo DB_PREFIX; ?>Roles 
WHERE Player = <?php echo $player; ?>;