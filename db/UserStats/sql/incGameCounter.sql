UPDATE <?php echo DB_PREFIX; ?>UserStats
SET FirstGame = <?php echo $first; ?>,
    LastGame = <?php echo $last; ?>,
    GameCount = GameCount + 1<?php
if ($mod) { ?>,
    ModeratorCount = ModeratorCount + 1
<?php } ?>
 WHERE UserId = <?php echo $id; ?>;