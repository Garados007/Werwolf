INSERT INTO <?php echo DB_PREFIX; ?>ChatLog
	(Chat, User, Message, SendDate) VALUES
	(<?php echo $chat; ?>, <?php echo $user; ?>, '<?php echo $text; ?>',
		<?php echo $time; ?>);