<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

$targetDir = "uploads/";

if (!file_exists($targetDir)) {
    mkdir($targetDir, 0777, true);
}

if (isset($_FILES["file"])) {

    $fileName = time() . "_" . basename($_FILES["file"]["name"]);
    $targetFile = $targetDir . $fileName;

    if (move_uploaded_file($_FILES["file"]["tmp_name"], $targetFile)) {

       echo json_encode([
    "success" => true,
    "file_url" => "http://10.164.73.246:8888/mujeer_api/" . $targetFile,
    "file_name" => basename($_FILES["file"]["name"])
]);

    } else {
        echo json_encode(["success" => false]);
    }

} else {
    echo json_encode(["success" => false]);
}
?>