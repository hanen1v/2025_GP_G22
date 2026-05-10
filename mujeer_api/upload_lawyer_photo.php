<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

error_reporting(E_ALL);
ini_set('display_errors', 1);

require_once __DIR__ . '/config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
  echo json_encode(["success" => false, "message" => "Invalid method"]);
  exit;
}

$lawyerId = isset($_POST['lawyer_id']) ? (int)$_POST['lawyer_id'] : 0;
if ($lawyerId <= 0) {
  echo json_encode(["success" => false, "message" => "Missing lawyer_id"]);
  exit;
}

if (!isset($_FILES['photo']) || $_FILES['photo']['error'] !== UPLOAD_ERR_OK) {
  echo json_encode(["success" => false, "message" => "No photo uploaded"]);
  exit;
}

$uploadDir = __DIR__ . '/uploads/';
if (!is_dir($uploadDir)) {
  mkdir($uploadDir, 0777, true);
}

$ext = pathinfo($_FILES['photo']['name'], PATHINFO_EXTENSION);
$ext = strtolower($ext);
if (!in_array($ext, ['jpg','jpeg','png'])) {
  echo json_encode(["success" => false, "message" => "Invalid file type"]);
  exit;
}

$fileName = 'lawyer_' . $lawyerId . '_' . time() . '.' . $ext;
$targetPath = $uploadDir . $fileName;

if (!move_uploaded_file($_FILES['photo']['tmp_name'], $targetPath)) {
  echo json_encode(["success" => false, "message" => "Failed to move uploaded file"]);
  exit;
}

// تحديث اسم الصورة في جدول المحامي
$stmt = $conn->prepare("UPDATE lawyer SET LawyerPhoto = ? WHERE LawyerID = ? LIMIT 1");
if (!$stmt) {
  echo json_encode(["success" => false, "message" => "DB error: " . $conn->error]);
  exit;
}

$stmt->bind_param("si", $fileName, $lawyerId);

if ($stmt->execute()) {
  echo json_encode([
    "success"  => true,
    "message"  => "تم تحديث الصورة بنجاح",
    "fileName" => $fileName
  ], JSON_UNESCAPED_UNICODE);
} else {
  echo json_encode(["success" => false, "message" => "Update failed: " . $stmt->error]);
}

$stmt->close();
$conn->close();
