<?php

include_once dirname(__FILE__).'/../../lang/Lang.php';

if (!isset($worker) || !$worker)
	header("Content-Type: application/javascript");

echo 'var Lang=new function(){var data=';
echo json_encode(Lang::GetString('ui-game', null));
echo ';this.Get=function(name,sub){if(sub==null)return data[name];';
echo 'else return data[name][sub];};};';