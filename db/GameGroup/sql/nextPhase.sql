UPDATE <?php echo DB_PREFIX; ?>Games
SET CurrentPhase = '<?php echo $next; ?>',
	CurrentLevel = <?php echo $level; ?>
 WHERE Id = <?php echo $id; ?>