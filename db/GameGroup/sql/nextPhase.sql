UPDATE <?php echo DB_PREFIX; ?>Games
SET CurrentPhase = '<?php echo $next; ?>',
	CurrentDay = <?php echo $day; ?>
 WHERE Id = <?php echo $id; ?>