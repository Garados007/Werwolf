SELECT Id, Game, ChatMode, Opened
FROM <?php echo DB_PREFIX; ?>Chats
WHERE Id = <?php echo $id; ?>;