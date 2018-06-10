SELECT Id, User, Chat, Message, SendDate
FROM <?php echo DB_PREFIX; ?>ChatLog
WHERE Chat IN (<?php echo implode(',',$chat); ?>)
	<?php if ($minId !== null) { ?>
	AND
	Id >= <?php echo $minId; ?>
	<?php } ?>
 ORDER BY Id ASC;