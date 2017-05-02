SELECT Id, MainGroup, Started, Finished, CurrentPhase
FROM <?php echo DB_PREFIX; ?>Games
WHERE Id = <?php echo $id; ?>