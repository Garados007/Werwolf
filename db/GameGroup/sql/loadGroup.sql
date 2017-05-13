SELECT Id, MainGroup, Started, Finished, CurrentPhase, CurrentLevel
FROM <?php echo DB_PREFIX; ?>Games
WHERE Id = <?php echo $id; ?>