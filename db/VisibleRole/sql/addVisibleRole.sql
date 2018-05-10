REPLACE INTO <?php echo DB_PREFIX; ?>VisibleRoles
	(Player, Target, RoleKey) VALUES 
<?php for ($i = 0; $i<count($roles); ++$i) {?>
<?php if ($i != 0) echo ','; ?>
	(<?php echo $player; ?>, <?php echo $target; ?>, '<?php echo $roles[$i]; ?>')
<?php } ?>;