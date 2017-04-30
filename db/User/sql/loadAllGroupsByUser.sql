SELECT GroupId, UserId
FROM <?php echo DB_PREFIX; ?>User
WHERE UserId = <?php echo $user; ?>