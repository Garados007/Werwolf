SELECT UserId, FirstGame, LastGame, GameCount, WinningCount, ModeratorCount,
    LastOnline, AiId, NameKey as AiNameKey, ControlClass as AiControlClass,
    TotalBanCount, TotalBanDays, PermaBanCount, SpokenBanCount
FROM <?php echo DB_PREFIX; ?>UserStats s
LEFT OUTER JOIN <?php echo DB_PREFIX; ?>AIInfo a ON (s.AIId = a.Id)

<?php switch ($filter) { 
     case "mostGames": ?>
ORDER BY GameCount Desc, WinningCount Desc, ModeratorCount Desc
<?php break; 
    case "mostWinGames": ?>
ORDER BY WinningCount Desc, GameCount Desc, ModeratorCount Desc
<?php break; 
    case "mostModGames": ?>
ORDER BY ModeratorCount Desc, GameCount Desc, WnningCount Desc
<?php break; 
    case "topWinner": ?>
WHERE GameCount > <?php echo SCORE_MIN_GAMES; ?>

ORDER BY WinningCount/GameCount Desc, GameCount Desc, ModeratorCount Desc
<?php break; 
    case "topMod": ?>
WHERE GameCount > <?php echo SCORE_MIN_GAMES; ?>

ORDER BY ModeratorCount/GameCount Desc, GameCount Desc, WinningCount Desc
<?php break; 
     case "mostWinGames": ?>
WHERE FALSE
<?php break; 
    } ?>

LIMIT <?php echo SCORE_MAX_ITEMS; ?>