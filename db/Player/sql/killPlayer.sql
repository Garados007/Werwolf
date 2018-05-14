UPDATE <?php echo DB_PREFIX; ?>Player
SET Alive = <?php echo $alive ? 'TRUE' : 'FALSE'; ?>,
	ExtraWolfLive = <?php echo $wolf ? 'TRUE' : 'FALSE'; ?>
 WHERE Id = <?php echo $id; ?>;