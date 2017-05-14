
ALTER TABLE <?php echo DB_PREFIX; ?>Games
	ADD CurrentLevel INT(8) NOT NULL
		AFTER CurrentPhase;

TRUNCATE <?php echo DB_PREFIX; ?>Phases;
		
ALTER TABLE <?php echo DB_PREFIX; ?>Phases
	ADD PhaseLevel INT(8) NOT NULL
		AFTER Phase,
	ADD NextPhaseLevel INT(8) NOT NULL
		AFTER NextPhase,
	DROP PRIMARY KEY,
	ADD PRIMARY KEY (Phase, PhaseLevel);


ALTER TABLE <?php echo DB_PREFIX; ?>Chats
	ADD EnableVoting BOOLEAN NOT NULL
		AFTER Opened;

