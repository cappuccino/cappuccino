<?php

date_default_timezone_set('UTC');
// current time
$in =  date("H:i:s:e", time());

$code = $_GET["status"];
http_response_code($code);

$sleep = $_GET["sleep"];
sleep($sleep);

$out = date("H:i:s:e", time());

echo json_encode(array($in,$out));

?>