SELECT GroupId, UserId, LastOnline
FROM <?php echo DB_PREFIX; ?>User
WHERE GroupId = <?php echo $group; ?>