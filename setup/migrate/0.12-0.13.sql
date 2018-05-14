-- Major change in database

-- drop old database
SET FOREIGN_KEY_CHECKS=0;
DROP TABLE IF EXISTS <?php echo DB_PREFIX; ?>ChatLog;
DROP TABLE IF EXISTS <?php echo DB_PREFIX; ?>Chats;
DROP TABLE IF EXISTS <?php echo DB_PREFIX; ?>ChatModes;
DROP TABLE IF EXISTS <?php echo DB_PREFIX; ?>ChatModeKeys;
DROP TABLE IF EXISTS <?php echo DB_PREFIX; ?>Games;
DROP TABLE IF EXISTS <?php echo DB_PREFIX; ?>Groups;
DROP TABLE IF EXISTS <?php echo DB_PREFIX; ?>Phases;
DROP TABLE IF EXISTS <?php echo DB_PREFIX; ?>Player;
DROP TABLE IF EXISTS <?php echo DB_PREFIX; ?>RoleModeKeys;
DROP TABLE IF EXISTS <?php echo DB_PREFIX; ?>Roles;
DROP TABLE IF EXISTS <?php echo DB_PREFIX; ?>User;
DROP TABLE IF EXISTS <?php echo DB_PREFIX; ?>VisibleRoles;
DROP TABLE IF EXISTS <?php echo DB_PREFIX; ?>Votes;
DROP TABLE IF EXISTS <?php echo DB_PREFIX; ?>VoteSetting;
SET FOREIGN_KEY_CHECKS=1;
