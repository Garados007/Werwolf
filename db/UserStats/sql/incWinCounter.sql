UPDATE <?php echo DB_PREFIX; ?>UserStats
SET WinningCount = WinningCount + 1
 WHERE UserId = <?php echo $id; ?>;