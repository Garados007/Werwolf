REPLACE INTO <?php echo DB_PREFIX; ?>VisibleRoles
	(Game, MainUser, TargetUser, RoleKey) VALUES 
<?php for ($i = 0; $i<count($roles); ++$i) {?>
<?php if ($i != 0) echo ','; ?>
	(<?php echo $game; ?>, <?php echo $main; ?>, <?php echo $target; ?>, '<?php echo $roles[$i]; ?>')
<?php } ?>;