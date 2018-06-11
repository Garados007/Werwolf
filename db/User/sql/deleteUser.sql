DELETE FROM <?php echo DB_PREFIX; ?>User
WHERE UserId = <?php echo $user; ?> AND
    GroupId = <?php echo $group; ?> AND
    Player IS NULL;

SELECT COUNT(*) AS "count"
FROM UserId = <?php echo $user; ?> AND
    GroupId = <?php echo $group; ?>;