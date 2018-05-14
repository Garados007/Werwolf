SELECT Id, MainGroup, Started, Finished, CurrentPhase, CurrentDay, RuleSet, Vars
FROM <?php echo DB_PREFIX; ?>Games
WHERE Id = <?php echo $id; ?>;