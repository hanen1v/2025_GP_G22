<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

error_reporting(E_ALL);
ini_set('display_errors', 1);

require_once __DIR__ . '/config.php';

if (!isset($_POST['lawyer_id']) || !isset($_POST['fileName'])) {
    echo json_encode(["success" => false, "message" => "Missing fields"]);
    exit;
}

$lawyerId  = (int)$_POST['lawyer_id'];
$fileName  = basename($_POST['fileName']);

if (!isset($_FILES['license_file']) || $_FILES['license_file']['error'] !== UPLOAD_ERR_OK) {
    echo json_encode(["success" => false, "message" => "لم يتم استقبال ملف الرخصة بشكل صحيح"]);
    exit;
}

$uploadDir = __DIR__ . '/uploads/';
if (!is_dir($uploadDir)) {
    @mkdir($uploadDir, 0777, true);
}

$targetPath = $uploadDir . $fileName;

if (!move_uploaded_file($_FILES['license_file']['tmp_name'], $targetPath)) {
    echo json_encode(["success" => false, "message" => "فشل في حفظ ملف الرخصة على السيرفر"]);
    exit;
}

echo json_encode([
    "success" => true,
    "message" => "تم رفع ملف الرخصة بنجاح"
], JSON_UNESCAPED_UNICODE);
