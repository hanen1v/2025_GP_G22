<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

error_reporting(E_ALL);
ini_set('display_errors', 1);

require_once __DIR__ . '/config.php';

$raw = file_get_contents("php://input");
$data = json_decode($raw, true);

if (!$data) {
  echo json_encode(["success" => false, "message" => "Invalid JSON"]);
  exit;
}

/*
  Required:
    userId   : int
    userType : "client" | "lawyer"
    password : string
*/

$required = ['userId','userType','password'];
foreach ($required as $f) {
  if (!isset($data[$f]) || $data[$f]==='') {
    echo json_encode(["success"=>false, "message"=>"Missing field: $f"]);
    exit;
  }
}

$userId   = (int)$data['userId'];
$userType = strtolower(trim($data['userType']));
$password = $data['password'];

$table = null; 
$idCol = null;

if ($userType === 'client') {
  $table = 'client';
  $idCol = 'ClientID';
} elseif ($userType === 'lawyer') {
  $table = 'lawyer';
  $idCol = 'LawyerID';
} else {
  echo json_encode(["success"=>false, "message"=>"Invalid userType"]);
  exit;
}

// تأكيد وجود المستخدم
$sel = $conn->query("SELECT $idCol, Username, PhoneNumber, Password FROM $table WHERE $idCol = $userId LIMIT 1");
if (!$sel || $sel->num_rows === 0) {
  echo json_encode(["success"=>false, "message"=>"User not found"]);
  exit;
}

$row = $sel->fetch_assoc();

// ✅ التحقق الإجباري من كلمة المرور
if (!password_verify($password, $row['Password'])) {
  echo json_encode(["success"=>false, "message"=>"كلمة المرور غير صحيحة"]);
  exit;
}

/***  Hard Delete: حذف نهائي من الجدول ***/

// لو المستخدم محامي نحذف طلباته أول من جدول request عشان الـ FK
if ($userType === 'lawyer') {
  $stmtReq = $conn->prepare("DELETE FROM request WHERE LawyerID = ?");
  if ($stmtReq) {
    $stmtReq->bind_param("i", $userId);
    $stmtReq->execute();
    $stmtReq->close();
  }
}

// بعدين نحذف الحساب نفسه من الجدول المناسب
$stmtDel = $conn->prepare("DELETE FROM $table WHERE $idCol = ? LIMIT 1");
if (!$stmtDel) {
  echo json_encode([
    "success" => false,
    "message" => "Prepare failed: " . $conn->error
  ], JSON_UNESCAPED_UNICODE);
  $conn->close();
  exit;
}

$stmtDel->bind_param("i", $userId);

if (!$stmtDel->execute()) {
  echo json_encode([
    "success" => false,
    "message" => "Delete failed: " . $stmtDel->error
  ], JSON_UNESCAPED_UNICODE);
  $stmtDel->close();
  $conn->close();
  exit;
}

$stmtDel->close();

echo json_encode([
  "success" => true,
  "message" => "تم حذف الحساب بنجاح"
], JSON_UNESCAPED_UNICODE);

$conn->close();
