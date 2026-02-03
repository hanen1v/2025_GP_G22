<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

// مهم: لا نطبع أخطاء HTML للعميل (Flutter)
error_reporting(E_ALL);
ini_set('display_errors', 0);      // ⛔ لا تطبعي الأخطاء على الشاشة
ini_set('log_errors', 1);          // ✅ سجّليها في اللوق
ini_set('error_log', __DIR__ . '/php_errors.log');

require_once __DIR__ . '/config.php';

$raw = file_get_contents("php://input");
$data = json_decode($raw, true);

if (!$data) {
    echo json_encode(["success" => false, "message" => "Invalid JSON"]);
    exit;
}

$lawyerId       = (int)($data['lawyerId']      ?? 0);
$fullName       = trim($data['fullName']       ?? '');
$licenseNumber  = trim($data['licenseNumber']  ?? '');

// تأكد من الحقول
if ($lawyerId <= 0 || $fullName === '' || $licenseNumber === '') {
    echo json_encode([
        "success" => false,
        "message" => "حقول ناقصة (lawyerId, fullName, licenseNumber مطلوبة)"
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

// اسم ملف مبدئي للرخصة الجديدة (رح نرفعها في API ثاني)
$licenseFileName = 'license_update_' . $lawyerId . '_' . time() . '.pdf';

/*
    نفترض أن جدول request فيه الأعمدة:
    RequestID (PK)
    AdminID
    LawyerID
    LawyerLicense
    LawyerName
    LicenseNumber
    Status
    RequestType   ← نستخدمه لتمييز "UpdateLicense" عن "NewLawyer" لو حبيتي
*/

$sql = "INSERT INTO request (AdminID, LawyerID, LawyerLicense, LawyerName, LicenseNumber, Status)
                    VALUES (1, ?, ?, ?, ?, 'Pending')";

$stmt = $conn->prepare($sql);
if (!$stmt) {
    echo json_encode([
        "success" => false,
        "message" => "SQL prepare error: " . $conn->error
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

$stmt->bind_param("isss", $lawyerId, $licenseFileName, $fullName, $licenseNumber);

if (!$stmt->execute()) {
    echo json_encode([
        "success" => false,
        "message" => "Insert failed: " . $stmt->error
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

$requestId = $conn->insert_id;

echo json_encode([
    "success"         => true,
    "message"         => "تم إرسال طلب تحديث الرخصة بنجاح",
    "requestId"       => $requestId,
    "licenseFileName" => $licenseFileName
], JSON_UNESCAPED_UNICODE);

$stmt->close();
$conn->close();
