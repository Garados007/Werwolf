SELECT Chat, VoteKey, Created, VoteStart, VoteEnd, 
    EnabledUser, TargetUser, ResultTarget
FROM <?php echo DB_PREFIX; ?>VoteSetting
WHERE Chat = <?php echo $chat; ?>;