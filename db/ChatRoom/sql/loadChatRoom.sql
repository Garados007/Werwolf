SELECT Id, Game, ChatMode, Opened, EnableVoting
FROM <?php echo DB_PREFIX; ?>Chats
WHERE Id = <?php echo $id; ?>;