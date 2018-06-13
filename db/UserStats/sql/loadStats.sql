SELECT UserId, FirstGame, LastGame, GameCount, WinningCount, ModeratorCount,
    LastOnline, AiId, NameKey as AiNameKey, ControlClass as AiControlClass,
    TotalBanCount, TotalBanDays, PermaBanCount, SpokenBanCount
FROM <?php echo DB_PREFIX; ?>UserStats s
LEFT OUTER JOIN <?php echo DB_PREFIX; ?>AIInfo a ON (s.AIId = a.Id)
WHERE s.UserId = <?php echo $id; ?>;