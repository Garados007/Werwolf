SELECT Setting, Voter, Target, VoteDate
FROM <?php echo DB_PREFIX; ?>Votes
WHERE Setting = <?php echo $setting; ?>;