UPDATE <?php echo DB_PREFIX; ?>Groups
SET	CurrentGame = <?php echo $game === null ? 'NULL' : $game; ?>
<?php if ($game !== null) { ?>,
	LastGame = <?php echo $time; ?>
<?php } ?>
 WHERE Id = <?php echo $id; ?>;
 
<?php if (!DB_USE_TRIGGER && $game === null && $oldgame !== null) { ?>

CREATE TEMPORARY TABLE _delChatIds_<?php echo $oldgame; ?> (
    Id INT UNSIGNED NOT NULL PRIMARY KEY,
    INDEX (Id)
) ENGINE=MEMORY AS (
	SELECT Id
	FROM <?php echo DB_PREFIX; ?>Chats
	WHERE Game = <?php echo $oldgame; ?>
);

DELETE FROM <?php echo DB_PREFIX; ?>VisibleRoles
WHERE Game = <?php echo $oldgame; ?>;

DELETE FROM <?php echo DB_PREFIX; ?>Votes
WHERE Chat IN (
	SELECT Id
	FROM _delChatIds_<?php echo $oldgame; ?>
);

DELETE FROM <?php echo DB_PREFIX; ?>VoteSettings
WHERE Chat IN (
	SELECT Id
	FROM _delChatIds_<?php echo $oldgame; ?>
);

DELETE FROM <?php echo DB_PREFIX; ?>ChatLog
WHERE Chat IN (
	SELECT Id
	FROM _delChatIds_<?php echo $oldgame; ?>
);

DELETE FROM <?php echo DB_PREFIX; ?>Chats
WHERE Game = <?php echo $oldgame; ?>;

DELETE FROM <?php echo DB_PREFIX; ?>Roles
WHERE Game = <?php echo $oldgame; ?>;

DELETE FROM <?php echo DB_PREFIX; ?>Player
WHERE Game = <?php echo $oldgame; ?>;

DELETE FROM <?php echo DB_PREFIX; ?>Games
WHERE Id = <?php echo $oldgame; ?>;

DROP TEMPORARY TABLE _delChatIds_<?php echo $oldgame; ?>;

<?php } ?>