SELECT Id, Game, ChatRoom
FROM <?php echo DB_PREFIX; ?>Chats
WHERE Id = <?php echo $id; ?>;