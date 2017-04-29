SELECT User, Message, SendDate
FROM <?php echo DB_PREFIX; ?>ChatLog
WHERE Chat = <?php echo $chat; ?>
	<?php if ($minSendDate !== null) { ?>
	AND
	SendDate >= <?php echo $minSendDate; ?>
	<?php } ?>;