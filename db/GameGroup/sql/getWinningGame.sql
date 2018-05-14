SELECT  Role
FROM <?php echo DB_PREFIX; ?>WinningGame
WHERE Game = <?php echo $game; ?>;