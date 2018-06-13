SELECT User, Spoker, GroupId, StartDate, EndDate, Comment
FROM <?php echo DB_PREFIX; ?>BanInfo
<?php switch ($mode) {
    case "fromUser": ?>

WHERE User = <?php echo $user; ?>
 ORDER BY StartDate ASC, EndDate ASC

<?php break;
    case "newest": ?>

ORDER BY StartDate DESC, EndDate ASC
LIMIT <?php echo SCORE_MAX_ITEMS; ?>

<?php break;
    case "oldest": ?>

ORDER BY StartDate ASC, EndDate ASC
LIMIT <?php echo SCORE_MAX_ITEMS; ?>

<?php break;
    case "spokenBy": ?>

WHERE Spoker = <?php echo $user; ?>
 ORDER BY StartDate ASC, EndDate ASC

<?php break;
    case "forGroup": ?>

WHERE GroupId = <?php echo $group; ?>
 ORDER BY StartDate ASC, EndDate ASC

<?php break;
    case "specific": ?>

WHERE User = <?php echo $user; ?> AND
    GroupId = <?php echo $group; ?>
 LIMIT 1

<?php break;
    default: ?>

WHERE 0

<?php break;
} ?>;
