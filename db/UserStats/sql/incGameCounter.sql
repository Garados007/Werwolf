UPDATE <?php echo DB_PREFIX; ?>UserStats
SET FirstGame = <?php echo $first; ?>,
    LastGame = <?php echo $last; ?>,
    GameCount = GameCount + 1<?php
if ($mod) { ?>,
    ModeratedCount = ModeratedCount + 1
<? } ?>
 WHERE UserId = <?php echo $id; ?>;