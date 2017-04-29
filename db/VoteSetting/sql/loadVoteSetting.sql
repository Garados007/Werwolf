SELECT Chat, VoteStart, VoteEnd, ResultTarget
FROM <?php echo DB_PREFIX; ?>VoteSetting
WHERE Chat = <?php echo $chat; ?>;