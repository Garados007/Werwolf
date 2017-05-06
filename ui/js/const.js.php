<?php

include_once dirname(__FILE__).'/../../db/ChatMode/ChatMode.php';

header("Content-Type: application/javascript");

echo 'var Const=Const||{};';
echo 'Const.ChatKeys='.json_encode(ChatMode::getChatKeys()).';';
echo 'Const.RoleKeys='.json_encode(ChatMode::getRoleKeys()).';';