UPDATE <?php echo DB_PREFIX; ?>Games
SET Vars= <?php echo $vars === null ? "NULL" : "'".$vars."'"; ?>
 WHERE Id = <?php echo $id; ?>