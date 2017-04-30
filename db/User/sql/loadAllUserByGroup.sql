SELECT GroupId, UserId
FROM <?php echo DB_PREFIX; ?>User
WHERE GroupId = <?php echo $group; ?>