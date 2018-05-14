SELECT Id, Name, Created, LastGame, Creator, Leader, CurrentGame, EnterKey
FROM <?php echo DB_PREFIX; ?>Groups
WHERE Id = <?php echo $id; ?>;