REPLACE INTO <?php echo DB_PREFIX; ?>ChatModes
	(ChatMode, SupportedRoleKey, EnableWrite, Visible) VALUES
	('common',   'storytel', TRUE,  TRUE),
	('common',   'villager', TRUE,  TRUE),
	('common',   'wolf',     TRUE,  TRUE),
	('common',   'major',    TRUE,  TRUE),
	('common',   'armor',    TRUE,  TRUE),
	('story',    'log',      TRUE,  TRUE),
	('story',    'storytel', TRUE,  TRUE),
	('story',    'villager', FALSE, TRUE),
	('story',    'wolf',     FALSE, TRUE),
	('story',    'major',    FALSE, TRUE),
	('story',    'armor',    FALSE, TRUE),
	('voteMajr', 'storytel', TRUE,  TRUE),
	('voteMajr', 'villager', TRUE,  TRUE),
	('voteMajr', 'wolf',     TRUE,  TRUE),
	('voteMajr', 'major',    TRUE,  TRUE),
	('voteMajr', 'armor',    TRUE,  TRUE),
	('voteArmr', 'storytel', TRUE,  TRUE),
	('voteArmr', 'armor',    TRUE,  TRUE),
	('voteVilg', 'storytel', TRUE,  TRUE),
	('voteVilg', 'villager', TRUE,  TRUE),
	('voteWolf', 'storytel', TRUE,  TRUE),
	('voteWolf', 'wolf',     TRUE,  TRUE),
	('lovepair', 'storytel', TRUE,  TRUE),
	('lovepair', 'pair',     TRUE,  TRUE)
;

REPLACE INTO <?php echo DB_PREFIX; ?>ChatModeKeys
	(ChatMode) VALUES
	('common'),
	('story'),
	('voteMajr'),
	('voteArmr'),
	('voteVilg'),
	('voteWolf'),
	('lovepair')
;

REPLACE INTO <?php echo DB_PREFIX; ?>RoleModeKeys
	(RoleKey) VALUES
	('log'),
	('storytel'),
	('villager'),
	('wolf'),
	('major'),
	('armor'),
	('pair')
;