REPLACE INTO <?php echo DB_PREFIX; ?>UserConfig
    (User, Config) VALUES
    (<?php echo $id; ?>, '<?php echo $config; ?>');
