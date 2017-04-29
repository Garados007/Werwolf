UPDATE <?php echo DB_PREFIX; ?>Games
SET CurrentPhase = '<?php echo $next; ?>'
WHERE Id = <?php echo $id; ?>