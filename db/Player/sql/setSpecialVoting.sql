UPDATE <?php echo DB_PREFIX; ?>Player
SET SpecialVoting = <?php echo $key; ?>
 WHERE Game = <?php echo $game; ?> AND User = <?php echo $user; ?>;