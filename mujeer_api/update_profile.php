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
    userId     : int
    userType   : "client" | "lawyer"
    username   : string
    phoneNumber: string (05XXXXXXXX)
  Optional:
    newPassword: string
*/

$required = ['userId','userType','username','phoneNumber'];
foreach ($required as $f) {
  if (!isset($data[$f]) || $data[$f]==='') {
    echo json_encode(["success"=>false, "message"=>"Missing field: $f"]);
    exit;
  }
}

$userId      = (int)$data['userId'];
$userType    = strtolower(trim($data['userType']));
$username    = $conn->real_escape_string(trim($data['username']));
$phoneNumber = $conn->real_escape_string(trim($data['phoneNumber']));
$newPassword = isset($data['newPassword']) ? $data['newPassword'] : '';

$table = null; $idCol = null;
if ($userType === 'client') { $table = 'client'; $idCol = 'ClientID'; }
elseif ($userType === 'lawyer') { $table = 'lawyer'; $idCol = 'LawyerID'; }
else {
  echo json_encode(["success"=>false, "message"=>"Invalid userType"]);
  exit;
}

// تأكد أن المستخدم موجود
$exists = $conn->query("SELECT $idCol FROM $table WHERE $idCol = $userId LIMIT 1");
if (!$exists || $exists->num_rows === 0) {
  echo json_encode(["success"=>false, "message"=>"User not found"]);
  exit;
}

// التحقق من التكرار لغيره
$check = $conn->query("
  SELECT Username, PhoneNumber, $idCol AS UID
  FROM $table
  WHERE ($idCol <> $userId) AND (Username = '$username' OR PhoneNumber = '$phoneNumber')
  LIMIT 1
");
if ($check && $check->num_rows > 0) {
  $row = $check->fetch_assoc();
  if ($row['Username'] === $username) {
    echo json_encode(["success"=>false, "message"=>"اسم المستخدم موجود مسبقاً"]);
    exit;
  }
  if ($row['PhoneNumber'] === $phoneNumber) {
    echo json_encode(["success"=>false, "message"=>"رقم الجوال موجود مسبقاً"]);
    exit;
  }
}

// تجهيز جملة التحديث
$sets = [];
$sets[] = "Username = '$username'";
$sets[] = "PhoneNumber = '$phoneNumber'";

if (!empty($newPassword)) {
  $hashed = password_hash($newPassword, PASSWORD_DEFAULT);
  $sets[] = "Password = '$hashed'";
}

$setClause = implode(", ", $sets);
$updSql = "UPDATE $table SET $setClause WHERE $idCol = $userId LIMIT 1";

if (!$conn->query($updSql)) {
  echo json_encode(["success"=>false, "message"=>"Update failed: ".$conn->error]);
  exit;
}

// رجّع السجل المحدّث بصيغة موحّدة
if ($userType === 'client') {
  $res = $conn->query("
    SELECT 
      ClientID   AS UserID,
      FullName,
      Username,
      PhoneNumber,
      Points
    FROM client
    WHERE ClientID = $userId
    LIMIT 1
  ");
  $user = $res && $res->num_rows ? $res->fetch_assoc() : null;

  echo json_encode([
    "success" => true,
    "message" => "تم تحديث البيانات بنجاح",
    "user"    => $user
  ], JSON_UNESCAPED_UNICODE);
} else {
  // lawyer
  $res = $conn->query("
    SELECT 
      LawyerID   AS UserID,
      FullName,
      Username,
      PhoneNumber,
      Status,
      LawyerPhoto AS ProfileImage
    FROM lawyer
    WHERE LawyerID = $userId
    LIMIT 1
  ");
  $user = $res && $res->num_rows ? $res->fetch_assoc() : null;

  echo json_encode([
    "success" => true,
    "message" => "تم تحديث البيانات بنجاح",
    "user"    => $user
  ], JSON_UNESCAPED_UNICODE);
}

$conn->close();
