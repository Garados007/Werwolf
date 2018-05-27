ALTER TABLE <?php echo DB_PREFIX; ?>Player
DROP FOREIGN KEY <?php echo DB_PREFIX; ?>player_ibfk_2;

ALTER TABLE <?php echo DB_PREFIX; ?>Player
ADD FOREIGN KEY (User) 
    REFERENCES <?php echo DB_PREFIX; ?>UserStats (UserId);