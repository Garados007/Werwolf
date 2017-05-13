
DROP TRIGGER IF EXISTS <?php echo DB_PREFIX; ?>Groups_RemoveCurrentGame;
CREATE TRIGGER <?php echo DB_PREFIX; ?>Groups_RemoveCurrentGame
	AFTER UPDATE ON <?php echo DB_PREFIX; ?>Groups
	FOR EACH ROW
BEGIN
	IF (NEW.CurrentGame IS NULL AND OLD.CurrentGame IS NOT NULL) THEN
		DELETE FROM <?php echo DB_PREFIX; ?>Games
		WHERE Id = OLD.CurrentGame;
	END IF;
END;

DROP TRIGGER IF EXISTS <?php echo DB_PREFIX; ?>Groups_DeleteGroup;
CREATE TRIGGER <?php echo DB_PREFIX; ?>Groups_DeleteGroup
	BEFORE DELETE ON <?php echo DB_PREFIX; ?>Groups
	FOR EACH ROW
BEGIN
	DELETE FROM <?php echo DB_PREFIX; ?>User
		WHERE GroupId = OLD.Id;
END;

DROP TRIGGER IF EXISTS <?php echo DB_PREFIX; ?>Games_DeleteGame;
CREATE TRIGGER <?php echo DB_PREFIX; ?>Games_DeleteGame
	BEFORE DELETE ON <?php echo DB_PREFIX; ?>Games
	FOR EACH ROW
BEGIN
	UPDATE <?php echo DB_PREFIX; ?>Groups
		SET CurrentGame = NULL
		WHERE CurrentGame = OLD.Id;
	DELETE FROM <?php echo DB_PREFIX; ?>Player
		WHERE Game = OLD.Id;
	DELETE FROM <?php echo DB_PREFIX; ?>Chats
		WHERE Game = OLD.Id;
END;

DROP TRIGGER IF EXISTS <?php echo DB_PREFIX; ?>Player_DeletePlayer;
CREATE TRIGGER <?php echo DB_PREFIX; ?>Player_DeletePlayer
	BEFORE DELETE ON <?php echo DB_PREFIX; ?>Player
	FOR EACH ROW
BEGIN
	DELETE FROM <?php echo DB_PREFIX; ?>Roles
		WHERE Game = OLD.Game AND User = OLD.User;
	DELETE FROM <?php echo DB_PREFIX; ?>VisibleRoles
		WHERE Game = OLD.Game AND
			(MainUser = OLD.User OR TargetUser = OLD.User);
END;

DROP TRIGGER IF EXISTS <?php echo DB_PREFIX; ?>Chats_DeleteChat;
CREATE TRIGGER <?php echo DB_PREFIX; ?>Chats_DeleteChat
	BEFORE DELETE ON <?php echo DB_PREFIX; ?>Chats
	FOR EACH ROW
BEGIN
	DELETE FROM <?php echo DB_PREFIX; ?>ChatLog
		WHERE Chat = OLD.Id;
	DELETE FROM <?php echo DB_PREFIX; ?>VoteSetting
		WHERE Chat = OLD.Id;
END;

DROP TRIGGER IF EXISTS <?php echo DB_PREFIX; ?>VoteSetting_DeleteVote;
CREATE TRIGGER <?php echo DB_PREFIX; ?>VoteSetting_DeleteVote
	BEFORE DELETE ON <?php echo DB_PREFIX; ?>VoteSetting
	FOR EACH ROW
BEGIN

	DELETE FROM <?php echo DB_PREFIX; ?>Votes
		WHERE Setting = OLD.Chat;
END;

