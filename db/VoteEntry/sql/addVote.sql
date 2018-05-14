REPLACE INTO <?php echo DB_PREFIX; ?>Votes
	(Setting, VoteKey, Voter, Target, VoteDate) VALUES
	(<?php echo $setting; ?>, '<?php echo $key; ?>', <?php echo $voter; ?>, 
		<?php echo $target; ?>, <?php echo $date; ?>);