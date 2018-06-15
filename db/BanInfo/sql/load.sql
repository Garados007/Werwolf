SELECT User, Spoker, GroupId, StartDate, EndDate, Comment
FROM <?php echo DB_PREFIX; ?>BanInfo
<?php switch ($mode) {
    case "fromUser": ?>

WHERE User = <?php echo $user; ?> AND
    (EndDate IS NULL OR EndDate >= <?php echo time(); ?>)
ORDER BY StartDate ASC, EndDate ASC

<?php break;
    case "newest": ?>

WHERE EndDate IS NULL OR EndDate >= <?php echo time(); ?>
 ORDER BY StartDate DESC, EndDate ASC
LIMIT <?php echo SCORE_MAX_ITEMS; ?>

<?php break;
    case "oldest": ?>

WHERE EndDate IS NULL OR EndDate >= <?php echo time(); ?>
 ORDER BY StartDate ASC, EndDate ASC
LIMIT <?php echo SCORE_MAX_ITEMS; ?>

<?php break;
    case "spokenBy": ?>

WHERE Spoker = <?php echo $user; ?> AND 
    (EndDate IS NULL OR EndDate >= <?php echo time(); ?>)
ORDER BY StartDate ASC, EndDate ASC

<?php break;
    case "forGroup": ?>

WHERE GroupId = <?php echo $group; ?> AND
    (EndDate IS NULL OR EndDate >= <?php echo time(); ?>)
ORDER BY StartDate ASC, EndDate ASC

<?php break;
    case "specific": ?>

WHERE User = <?php echo $user; ?> AND
    GroupId = <?php echo $group; ?> AND
    (EndDate IS NULL OR EndDate >= <?php echo time(); ?>)
LIMIT 1

<?php break;
    default: ?>

WHERE 0

<?php break;
} ?>;
