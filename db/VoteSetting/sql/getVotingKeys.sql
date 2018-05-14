SELECT VoteKey
FROM <?php echo DB_PREFIX; ?>VoteSetting
WHERE Chat = <?php echo $chat; ?>;