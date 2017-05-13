UPDATE <?php echo DB_PREFIX; ?>Chats
SET Opened = <?php echo $opened ? 'TRUE' : 'FALSE'; ?>,
	EnableVoting = <?php echo $enablev ? 'TRUE' : 'FALSE'; ?>
 WHERE Id = <?php echo $id; ?>;