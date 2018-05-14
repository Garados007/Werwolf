<?php
header("Content-Type: text/html");
ob_implicit_flush(true);
?>
<html>
<head>
	<meta charset="utf-8" />
	<title>Automatic Setup Page</title>
</head>
<body>
	<h1>Automatic Setup</h1>
	<h3>Log:</h3>
	<div style="background-color: lightgray; min-height: 50px; font-family: monospace;overflow-x: auto;">
		<div style="margin: 0.5em; white-space: pre; "><?php

	include "routines.php";
	
?>	
		</div>
	</div>
</body>
</html>
