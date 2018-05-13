<?php if ($aiName !== null && $aiClass !== null) { ?>

INSERT INTO <?php echo DB_PREFIX; ?>AIInfo
    (NameKey, ControlClass) VALUES
    ('<?php echo $aiName; ?>', '<?php echo $aiClass; ?>');

SELECT LAST_INSERT_ID() INTO @id;

<? } ?>

INSERT INTO <?php echo DB_PREFIX; ?>UserStats
    (UserId, FirstGame, LastGame, GameCount, WinningCount, ModeratorCount,
        LastOnline, AIId) VALUES
    (<?php echo $id; ?>, NULL, NULL, 0, 0, 0, <?php echo time(); ?>,
    <?php echo $aiName !== null && $aiClass !== null ? '@id' : 'NULL'; ?>);
