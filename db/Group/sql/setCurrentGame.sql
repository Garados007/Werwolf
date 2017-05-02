UPDATE <?php echo DB_PREFIX; ?>Groups
SET	CurrentGame = <?php echo $game === null ? 'NULL' : $game; ?>
<?php if ($game !== null) { ?>,
	LastGame = <?php echo $time; ?>
<?php } ?>
 WHERE Id = <?php echo $id; ?>;