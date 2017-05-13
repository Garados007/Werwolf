SELECT Phase, PhaseLevel, NextPhase, NextPhaseLevel
FROM <?php echo DB_PREFIX; ?>Phases
WHERE Phase = '<?php echo $id; ?>' AND
	PhaseLevel = <?php echo $level; ?>;