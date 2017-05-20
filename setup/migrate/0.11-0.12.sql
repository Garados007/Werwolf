
ALTER TABLE <?php echo DB_PREFIX; ?>Player
	ADD SpecialVoting INT(8) NOT NULL DEFAULT 0
		AFTER ExtraWolfLive;