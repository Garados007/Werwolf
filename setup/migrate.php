<?php

$version = is_file(dirname(__FILE__).'/version.txt') ?
	file_get_contents(dirname(__FILE__).'/version.txt') : null;
$versions = json_decode(file_get_contents(dirname(__FILE__).'/versions.json'),
	true);
	
if ($version === null) $version = $versions[count($versions)-1];

$start = 0;
for ($i = 0; $i<count($versions); ++$i)
	if ($versions[$i] == $version) {
		$start = $i;
		break;
	}

for (; $start<count($versions)-1; ++$start) {
	$file = dirname(__FILE__).'/migrate/'.$versions[$start].'-'
		.$versions[$start+1].'.sql';
	echo '<br/>Migrate Database version:  '.$versions[$start]
		.' ---> '.$versions[$start+1];
	if (is_file($file)) {
		if (!execSql($file)) return;
	}
}

$version = $versions[count($versions)-1];
file_put_contents(dirname(__FILE__).'/version.txt', $version);