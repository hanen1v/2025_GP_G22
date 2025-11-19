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

$lawyerId = isset($data['userId']) ? (int)$data['userId'] : 0;
if ($lawyerId <= 0) {
    echo json_encode(["success" => false, "message" => "Invalid userId"]);
    exit;
}

// نبني جملة الـ UPDATE حسب الحقول اللي وصلت فعلاً
$updates = [];

// username
if (!empty($data['username'])) {
    $username = $conn->real_escape_string($data['username']);
    $updates[] = "Username = '$username'";
}

// phone
if (!empty($data['phoneNumber'])) {
    $phone = $conn->real_escape_string($data['phoneNumber']);
    $updates[] = "PhoneNumber = '$phone'";
}

// password (لو وصلت && مو فاضية → نحدّثها)
if (!empty($data['password'])) {
    $hashed = password_hash($data['password'], PASSWORD_DEFAULT);
    $updates[] = "Password = '$hashed'";
}

// YearsOfExp (حتى لو 0 نمسكها بـ isset)
if (isset($data['yearsOfExp'])) {
    $years = (int)$data['yearsOfExp'];
    $updates[] = "YearsOfExp = $years";
}

// MainSpecialization
if (!empty($data['mainSpecialization'])) {
    $m = $conn->real_escape_string($data['mainSpecialization']);
    $updates[] = "MainSpecialization = '$m'";
}

// FSubSpecialization
if (!empty($data['fSubSpecialization'])) {
    $s1 = $conn->real_escape_string($data['fSubSpecialization']);
    $updates[] = "FSubSpecialization = '$s1'";
}

// SSubSpecialization
if (!empty($data['sSubSpecialization'])) {
    $s2 = $conn->real_escape_string($data['sSubSpecialization']);
    $updates[] = "SSubSpecialization = '$s2'";
}

// EducationQualification
if (!empty($data['educationQualification'])) {
    $deg = $conn->real_escape_string($data['educationQualification']);
    $updates[] = "EducationQualification = '$deg'";
}

// AcademicMajor
if (!empty($data['academicMajor'])) {
    $maj = $conn->real_escape_string($data['academicMajor']);
    $updates[] = "AcademicMajor = '$maj'";
}

if (empty($updates)) {
    echo json_encode(["success" => false, "message" => "No fields to update"]);
    exit;
}

$sql = "UPDATE lawyer SET " . implode(', ', $updates) . " WHERE LawyerID = $lawyerId LIMIT 1";
if (!$conn->query($sql)) {
    if ($conn->errno == 1062) {
        echo json_encode(["success" => false, "message" => "اسم المستخدم أو رقم الجوال مستخدم مسبقاً"]);
    } else {
        echo json_encode(["success" => false, "message" => "Update failed: " . $conn->error]);
    }
    exit;
}

// بعد التحديث نرجع البيانات المحدّثة عشان نخزنها في الـ Session
$uRes = $conn->query("
    SELECT 
      LawyerID           AS UserID,
      FullName,
      Username,
      PhoneNumber,
      Points,
      Status,
      YearsOfExp,
      MainSpecialization,
      FSubSpecialization,
      SSubSpecialization,
      EducationQualification,
      AcademicMajor,
      LawyerPhoto
    FROM lawyer
    WHERE LawyerID = $lawyerId
    LIMIT 1
");

if (!$uRes || $uRes->num_rows === 0) {
    echo json_encode(["success" => false, "message" => "User not found after update"]);
    exit;
}

$user = $uRes->fetch_assoc();

echo json_encode([
    "success" => true,
    "message" => "تم تحديث البيانات بنجاح",
    "user"    => $user
], JSON_UNESCAPED_UNICODE);

$conn->close();
