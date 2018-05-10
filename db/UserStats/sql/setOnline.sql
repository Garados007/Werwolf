UPDATE <?php echo DB_PREFIX; ?>UserStats
SET LastOnline = <?php echo $time; ?>
 WHERE UserId = <?php echo $id; ?>;