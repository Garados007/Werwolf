SELECT Id
FROM <?php echo DB_PREFIX; ?>Chats
WHERE Game = <?php echo $game; ?>;
