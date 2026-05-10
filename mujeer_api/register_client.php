<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

// تفعيل السجلات
error_reporting(E_ALL);
ini_set('display_errors', 1);

include 'config.php';

// سجل البيانات المستلمة
$raw_input = file_get_contents("php://input");
error_log("=== CLIENT REGISTRATION ATTEMPT ===");
error_log("Raw input: " . $raw_input);

$data = json_decode($raw_input);

if($data === null) {
    error_log("ERROR: JSON decode failed");
    echo json_encode(["success" => false, "message" => "بيانات غير صالحة"]);
    exit;
}

// التحقق من البيانات المطلوبة
$required_fields = ['username', 'fullName', 'password', 'phoneNumber'];

foreach($required_fields as $field) {
    if(!isset($data->$field) || empty($data->$field)) {
        error_log("ERROR: Missing field: " . $field);
        echo json_encode(["success" => false, "message" => "حقل {$field} مطلوب"]);
        exit;
    }
}

// استخراج البيانات
$username = $conn->real_escape_string($data->username);
$fullName = $conn->real_escape_string($data->fullName);
$password = $data->password;
$phoneNumber = $conn->real_escape_string($data->phoneNumber);

error_log("Processing client registration for: " . $username);

// التحقق من عدم تكرار اسم المستخدم أو رقم الجوال
$check_sql = "SELECT Username, PhoneNumber FROM client 
              WHERE Username = '$username' OR PhoneNumber = '$phoneNumber'";
$check_result = $conn->query($check_sql);

if($check_result && $check_result->num_rows > 0) {
    while($existing = $check_result->fetch_assoc()) {
        if($existing['Username'] == $username) {
            error_log("ERROR: Username already exists");
            echo json_encode(["success" => false, "message" => "اسم المستخدم موجود مسبقاً"]);
            exit;
        }
        if($existing['PhoneNumber'] == $phoneNumber) {
            error_log("ERROR: Phone number already exists");
            echo json_encode(["success" => false, "message" => "رقم الجوال موجود مسبقاً"]);
            exit;
        }
    }
}

// تشفير كلمة المرور
$hashed_password = password_hash($password, PASSWORD_DEFAULT);

// إدخال البيانات في جدول client
$sql = "INSERT INTO client (Username, FullName, PhoneNumber, Password, Points) 
        VALUES ('$username', '$fullName', '$phoneNumber', '$hashed_password', 0)";

error_log("Executing SQL: " . $sql);

if($conn->query($sql) === TRUE) {
    error_log("SUCCESS: Client registered successfully");
    
  $newId = $conn->insert_id;

  // اجلب نفس السجل الذي تم إدخاله الآن
  $uRes = $conn->query("
    SELECT 
      ClientID   AS UserID,
      FullName,
      Username,
      PhoneNumber,
      Points
    FROM client
    WHERE ClientID = $newId
    LIMIT 1
  ");

  $user = null;
  if ($uRes && $uRes->num_rows === 1) {
    $user = $uRes->fetch_assoc();
  }

  echo json_encode([
    "success" => true,
    "message" => "تم تسجيل العميل بنجاح!",
    "user"    => $user
  ], JSON_UNESCAPED_UNICODE);
} else {
    error_log("ERROR: Database insert failed - " . $conn->error);
    echo json_encode(["success" => false, "message" => "فشل في التسجيل: " . $conn->error]);
}

$conn->close();
?>