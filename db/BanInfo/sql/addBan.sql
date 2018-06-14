<?php if (!$kick) { ?>

INSERT INTO <?php echo DB_PREFIX; ?>BanInfo
    (User, Spoker, GroupId, StartDate, EndDate, Comment)
VALUES (<?php echo $user; ?>, <?php echo $spoker; ?>,
    <?php echo $group; ?>, <?php echo time(); ?>,
    <?php echo $end===null?'NULL':$end; ?>, '<?php echo $comment; ?>');

UPDATE <?php echo DB_PREFIX; ?>UserStats
SET TotalBanCount=TotalBanCount+1,
    TotalBanDays=TotalBanDays+<?php echo $end===null ? 0 : floor(($end-time()) / 86400); ?>,
    PermaBanCount=PermaBanCount+<?php echo $end===null ? 1 : 0; ?>
 WHERE UserId=<?php echo $user; ?>;

UPDATE <?php echo DB_PREFIX; ?>UserStats
SET SpokenBanCount=SpokenBanCount+1
WHERE UserId=<?php echo $spoker; ?>;

<?php } ?>

<?php if ($player !== null) { ?>

DELETE FROM <?php echo DB_PREFIX; ?>VisibleRoles
WHERE Player=<?php echo $player; ?> OR Target=<?php echo $player; ?>;

DELETE FROM <?php echo DB_PREFIX; ?>Roles
WHERE Player=<?php echo $player; ?>;

UPDATE <?php echo DB_PREFIX; ?>VoteSetting
SET ResultTarget=NULL
WHERE ResultTarget=<?php echo $player; ?>;

UPDATE <?php echo DB_PREFIX; ?>VoteSetting
SET EnabledUser=SUBSTRING(
        REPLACE(
            CONCAT(',',EnabledUser,','),
            '<?php echo ','.$player.','; ?>',
            ','
        ),
        2,
        LENGTH(
            REPLACE(
                CONCAT(',',EnabledUser,','),
                '<?php echo ','.$player.','; ?>',
                ','
            )
        ) - 2
    ),
    EnabledUserCount=EnabledUserCount - 1
WHERE CONCAT(',',EnabledUser,',') LIKE '%,<?php echo $player; ?>,%';

UPDATE <?php echo DB_PREFIX; ?>VoteSetting
SET TargetUser=SUBSTRING(
        REPLACE(
            CONCAT(',',TargetUser,','),
            '<?php echo ','.$player.','; ?>',
            ','
        ),
        2,
        LENGTH(
            REPLACE(
                CONCAT(',',TargetUser,','),
                '<?php echo ','.$player.','; ?>',
                ','
            )
        ) - 2
    ),
    TargetUserCount=TargetUserCount - 1
WHERE CONCAT(',',TargetUser,',') LIKE '%,<?php echo $player; ?>,%';

UPDATE <?php echo DB_PREFIX; ?>VoteSetting
SET VoteStart=IFNULL(VoteStart, <?php echo time(); ?>),
    VoteEnd=IFNULL(VoteEnd, <?php echo time(); ?>)
WHERE EnabledUserCount=0 OR TargetUserCount=0;

DELETE FROM <?php echo DB_PREFIX; ?>Votes
WHERE Voter=<?php echo $player; ?> OR Target=<?php echo $player; ?>;

UPDATE <?php echo DB_PREFIX; ?>User
SET Player=NULL
WHERE UserId=<?php echo $user; ?> AND GroupId=<?php echo $group; ?>;

DELETE FROM <?php echo DB_PREFIX; ?>Player
WHERE Id=<?php echo $player; ?>;

<?php } ?>

DELETE FROM <?php echo DB_PREFIX; ?>User
WHERE UserId=<?php echo $user; ?> AND GroupId=<?php echo $group; ?>;
