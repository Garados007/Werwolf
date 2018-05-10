SELECT Setting, VoteKey, Voter, Target, VoteDate
FROM <?php echo DB_PREFIX; ?>Votes
WHERE Setting = <?php echo $setting; ?> AND VoteKey = <?php echo $key; ?>;