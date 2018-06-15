DELETE FROM <?php echo DB_PREFIX; ?>BanInfo
WHERE (User, GroupId) = (<?php echo $user; ?>, <?php echo $group; ?>);

UPDATE <?php echo DB_PREFIX; ?>UserStats
SET TotalBanDays=TotalBanDays+<?php echo $days?>,
    PermaBanCount=PermaBanCount-<?php echo $perma ? 1 : 0; ?>
 WHERE UserId=<?php echo $user; ?>;

DELETE FROM <?php echo DB_PREFIX; ?>BanInfo
WHERE IFNULL(EndDate < <?php echo time(); ?>, FALSE);
