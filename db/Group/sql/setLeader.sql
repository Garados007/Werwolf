UPDATE <?php echo DB_PREFIX; ?>Groups
SET	Leader = <?php echo $leader; ?>
 WHERE Id = <?php echo $id; ?>;
