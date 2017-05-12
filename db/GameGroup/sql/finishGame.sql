UPDATE <?php echo DB_PREFIX; ?>Games
SET Finished = <?php echo $finished; ?>
 WHERE Id = <?php echo $id; ?>