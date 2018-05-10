UPDATE <?php echo DB_PREFIX; ?>Player
SET Vars= <?php echo $vars === null ? "NULL" : "'".$vars."'"; ?>
 WHERE Id = <?php echo $id; ?>;