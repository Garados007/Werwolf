ALTER TABLE <?php echo DB_PREFIX; ?>UserStats
    ADD TotalBanCount INT UNSIGNED NOT NULL DEFAULT 0
        AFTER AIId,
    ADD TotalBanDays INT UNSIGNED NOT NULL DEFAULT 0
        AFTER TotalBanCount,
    ADD PermaBanCount INT UNSIGNED NOT NULL DEFAULT 0
        AFTER TotalBanDays,
    ADD SpokenBanCount INT UNSIGNED NOT NULL DEFAULT 0
        AFTER PermaBanCount;

UPDATE <?php echo DB_PREFIX; ?>Games
SET RuleSet='test'
WHERE RuleSet='main';
