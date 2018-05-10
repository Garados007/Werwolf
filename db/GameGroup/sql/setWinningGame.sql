DELETE FROM <?php echo DB_PREFIX; ?>WinningGame
WHERE Game = <?php echo $game; ?>;

INSERT INTO <?php echo DB_PREFIX; ?>WinningGame
    (Game, Role) VALUES
<?php for ($i = 0; $i<count($roles); ++$i) { ?>
<?php if ($i != 0) echo ','; ?>
    (<?php echo $game; ?>, <?php echo $roles[$i]; ?>)
<?php } ?>;
