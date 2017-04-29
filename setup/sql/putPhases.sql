REPLACE INTO <?php echo DB_PREFIX; ?>Phases
	(Phase, NextPhase) VALUES
	('mainstor', 'majorsel'),
	('majorsel', 'villkill'),
	('villkill', 'sleepnow'),
	('sleepnow', 'armorsel'),
	('armorsel', 'wolfkill'),
	('wolfkill', 'awakenin'),
	('awakenin', 'villkill')
;