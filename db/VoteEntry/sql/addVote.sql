INSERT INTO <?php echo DB_PREFIX; ?>Votes
	(Setting, Voter, Target, VoteDate) VALUES
	(<?php echo $setting; ?>, <?php echo $voter; ?>, <?php echo $target; ?>,
		<?php echo $date; ?>);