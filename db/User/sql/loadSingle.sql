SELECT GroupId, UserId, Player
FROM <?php echo DB_PREFIX; ?>User
WHERE UserId = <?php echo $user; ?> AND
    GroupId = <?php echo $group; ?>;