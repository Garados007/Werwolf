SELECT User, Config
FROM <?php echo DB_PREFIX; ?>UserConfig
WHERE User = <?php echo $id; ?>;