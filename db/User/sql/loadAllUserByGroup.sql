SELECT GroupId, UserId, Player
FROM <?php echo DB_PREFIX; ?>User
WHERE GroupId = <?php echo $group; ?>;