<?php

require_once __DIR__ . '/config.php';

header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

$clientId = isset($_GET['id']) ? intval($_GET['id']) : 0;

if($clientId==0){

echo json_encode([
"success"=>false,
"points"=>0
]);

exit;

}

$stmt=$conn->prepare("
SELECT Points
FROM client
WHERE ClientID=?
");

$stmt->bind_param(
"i",
$clientId
);

$stmt->execute();

$result=$stmt->get_result();

if($row=$result->fetch_assoc()){

echo json_encode([
"success"=>true,
"points"=>$row['Points']
]);

}else{

echo json_encode([
"success"=>true,
"points"=>0
]);

}

$stmt->close();

$conn->close();

?>