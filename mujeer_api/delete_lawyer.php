<<<<<<< HEAD
<?php
require_once __DIR__ . '/config.php'; 
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Headers: Content-Type');
header('Content-Type: application/json; charset=utf-8');

// قراءة البيانات القادمة من Flutter
$raw = file_get_contents('php://input');
$data = json_decode($raw, true);

// تحقق من المدخلات
if (!is_array($data) || !isset($data['LawyerID'])) {
    http_response_code(400);
    echo json_encode(['ok' => false, 'message' => 'Missing or invalid LawyerID'], JSON_UNESCAPED_UNICODE);
    exit;
}

$lawyerId = intval($data['LawyerID']);

try {
    // تحقق أن المحامي موجود
    $checkLawyer = $conn->prepare("SELECT LawyerID FROM lawyer WHERE LawyerID = ?");
    $checkLawyer->bind_param("i", $lawyerId);
    $checkLawyer->execute();
    $resultLawyer = $checkLawyer->get_result();

    if ($resultLawyer->num_rows === 0) {
        http_response_code(404);
        echo json_encode(['ok' => false, 'message' => 'Lawyer not found'], JSON_UNESCAPED_UNICODE);
        exit;
    }

    // تحقق من وجود مواعيد نشطة أو قادمة
    $checkAppointments = $conn->prepare("
        SELECT COUNT(*) AS cnt 
        FROM appointment 
        WHERE LawyerID = ? 
          AND (Status IN ('active','upcoming'))
    ");
    $checkAppointments->bind_param("i", $lawyerId);
    $checkAppointments->execute();
    $resultAppointments = $checkAppointments->get_result();
    $row = $resultAppointments->fetch_assoc();

    if ($row && intval($row['cnt']) > 0) {
        http_response_code(409);
        echo json_encode([
            'ok' => false,
            'code' => 'LAWYER_HAS_APPOINTMENTS',
            'message' => 'Cannot delete: lawyer has active or upcoming appointments'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    // تنفيذ الحذف
    $delete = $conn->prepare("DELETE FROM lawyer WHERE LawyerID = ?");
    $delete->bind_param("i", $lawyerId);
    $delete->execute();

    if ($delete->affected_rows > 0) {
        echo json_encode(['ok' => true], JSON_UNESCAPED_UNICODE);
    } else {
        http_response_code(500);
        echo json_encode(['ok' => false, 'message' => 'Delete failed'], JSON_UNESCAPED_UNICODE);
    }

} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode([
        'ok' => false,
        'message' => 'Server error',
        'detail' => $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}

// إغلاق الاتصال
$conn->close();
?>
=======
<?php
require_once __DIR__ . '/config.php'; 
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Headers: Content-Type');
header('Content-Type: application/json; charset=utf-8');

// قراءة البيانات القادمة من Flutter
$raw = file_get_contents('php://input');
$data = json_decode($raw, true);

// تحقق من المدخلات
if (!is_array($data) || !isset($data['LawyerID'])) {
    http_response_code(400);
    echo json_encode(['ok' => false, 'message' => 'Missing or invalid LawyerID'], JSON_UNESCAPED_UNICODE);
    exit;
}

$lawyerId = intval($data['LawyerID']);

try {
    // تحقق أن المحامي موجود
    $checkLawyer = $conn->prepare("SELECT LawyerID FROM lawyer WHERE LawyerID = ?");
    $checkLawyer->bind_param("i", $lawyerId);
    $checkLawyer->execute();
    $resultLawyer = $checkLawyer->get_result();

    if ($resultLawyer->num_rows === 0) {
        http_response_code(404);
        echo json_encode(['ok' => false, 'message' => 'Lawyer not found'], JSON_UNESCAPED_UNICODE);
        exit;
    }

    // تحقق من وجود مواعيد نشطة أو قادمة
    $checkAppointments = $conn->prepare("
        SELECT COUNT(*) AS cnt 
        FROM appointment 
        WHERE LawyerID = ? 
          AND (Status IN ('active','upcoming'))
    ");
    $checkAppointments->bind_param("i", $lawyerId);
    $checkAppointments->execute();
    $resultAppointments = $checkAppointments->get_result();
    $row = $resultAppointments->fetch_assoc();

    if ($row && intval($row['cnt']) > 0) {
        http_response_code(409);
        echo json_encode([
            'ok' => false,
            'code' => 'LAWYER_HAS_APPOINTMENTS',
            'message' => 'Cannot delete: lawyer has active or upcoming appointments'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    // تنفيذ الحذف
    $delete = $conn->prepare("DELETE FROM lawyer WHERE LawyerID = ?");
    $delete->bind_param("i", $lawyerId);
    $delete->execute();

    if ($delete->affected_rows > 0) {
        echo json_encode(['ok' => true], JSON_UNESCAPED_UNICODE);
    } else {
        http_response_code(500);
        echo json_encode(['ok' => false, 'message' => 'Delete failed'], JSON_UNESCAPED_UNICODE);
    }

} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode([
        'ok' => false,
        'message' => 'Server error',
        'detail' => $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}

// إغلاق الاتصال
$conn->close();
?>
>>>>>>> d314d5dd75ed36b3837bd2d6d2eab010344b0a09
