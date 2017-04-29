SELECT Phase, NextPhase
FROM <?php echo DB_PREFIX; ?>Phases
WHERE Phase = <?php echo $id; ?>;