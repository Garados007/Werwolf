REPLACE INTO <?php echo DB_PREFIX; ?>Phases
	(Phase, PhaseLevel, NextPhase, NextPhaseLevel) VALUES
	('mainstor', 0, 'sleepnow', 0),
	
	('sleepnow', 0, 'armorsel', 0),
	('armorsel', 0, 'wolfkill', 0),
	('wolfkill', 0, 'oraclesl', 0),
	('oraclesl', 0, 'awakenin', 0),
	('awakenin', 0, 'majorsel', 0),
	('majorsel', 0, 'villkill', 0),
	('villkill', 0, 'sleepnow', 1),
	
	('sleepnow', 1, 'wolfkill', 1),
	('wolfkill', 1, 'oraclesl', 1),
	('oraclesl', 1, 'awakenin', 1),
	('awakenin', 1, 'villkill', 1),
	('villkill', 1, 'sleepnow', 1)
;