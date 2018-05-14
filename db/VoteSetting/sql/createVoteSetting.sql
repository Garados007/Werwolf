INSERT INTO <?php echo DB_PREFIX; ?>VoteSetting
	(Chat, VoteKey, Created, VoteStart, VoteEnd, EnabledUser,
		EnabledUserCount, TargetUser, TargetUserCount, ResultTarget) VALUES
	(<?php echo $chat; ?>, '<?php echo $key; ?>', <?php echo time(); ?>,
		<?php echo $start === null ? 'NULL' : $start; ?>, 
		<?php echo $end === null ? 'NULL' : $end; ?>,
		'<?php echo implode(',', $enabled); ?>', <?php echo count($enabled); ?>,
		'<?php echo implode(',', $target); ?>', <?php echo count($target); ?>,
		NULL);