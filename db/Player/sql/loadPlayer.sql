SELECT Id, Game, User, Alive, ExtraWolfLive, Vars
FROM <?php echo DB_PREFIX; ?>Player
WHERE Id = <?php echo $id; ?>;