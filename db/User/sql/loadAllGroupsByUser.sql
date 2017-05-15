SELECT GroupId, UserId, LastOnline
FROM <?php echo DB_PREFIX; ?>User
WHERE UserId = <?php echo $user; ?>