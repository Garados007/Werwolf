UPDATE <?php echo DB_PREFIX; ?>Player
SET Alive = <?php echo $alive ? 'TRUE' : 'FALSE'; ?>,
	ExtraWolfLive = <?php echo $wolf ? 'TRUE' : 'FALSE'; ?>
 WHERE Game = <?php echo $game; ?> AND User = <?php echo $user; ?>;