DELETE FROM <?php echo DB_PREFIX; ?>User
WHERE UserId = <?php echo $user; ?> AND
    GroupId = <?php echo $group; ?> AND
    Player IS NULL;

SELECT COUNT(*) AS "count"
FROM <?php echo DB_PREFIX; ?>User
WHERE UserId = <?php echo $user; ?> AND
    GroupId = <?php echo $group; ?>;

DELETE FROM <?php echo DB_PREFIX; ?>Groups
WHERE Id = <?php echo $group; ?> AND
    0 = ( SELECT COUNT(*) 
	    FROM <?php echo DB_PREFIX; ?>User
	    WHERE GroupId = <?php echo $group; ?>
	);
