<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

require_once __DIR__ . '/config.php';

header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

// قراءة البيانات من POST
$lawyerId   = isset($_POST['lawyer_id'])   ? intval($_POST['lawyer_id'])   : 0;
$clientId   = isset($_POST['client_id'])   ? intval($_POST['client_id'])   : 0;
$timeslotId = isset($_POST['timeslot_id']) ? intval($_POST['timeslot_id']) : 0;
$price      = isset($_POST['price'])       ? floatval($_POST['price'])     : 0;
$details    = isset($_POST['details'])     ? trim($_POST['details'])       : '';
$fileName   = isset($_POST['file_name'])   ? trim($_POST['file_name'])     : null;

if ($lawyerId == 0 || $clientId == 0 || $timeslotId == 0 || $price <= 0 || $details === '') {
    echo json_encode([
        "success" => false,
        "message" => "بيانات ناقصة"
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

try {
    $conn->begin_transaction();

    // 1) إنشاء الموعد
    $stmt = $conn->prepare("
        INSERT INTO appointment (LawyerID, ClientID, DateTime, Status, Price, timeslot_id)
        VALUES (?, ?, NOW(), 'Upcoming', ?, ?)
    ");
    $stmt->bind_param("iidi", $lawyerId, $clientId, $price, $timeslotId);
    $stmt->execute();

    if ($stmt->affected_rows <= 0) {
        throw new Exception("فشل إنشاء الموعد");
    }

    $appointmentId = $stmt->insert_id;
    $stmt->close();

    // 2) تفاصيل الاستشارة
    $stmt2 = $conn->prepare("
        INSERT INTO consultation (AppointmentID, Details, File)
        VALUES (?, ?, ?)
    ");
    $stmt2->bind_param("iss", $appointmentId, $details, $fileName);
    $stmt2->execute();
    $stmt2->close();

    // 3) تحديث نقاط المحامي (تزيد بعدد السعر)
    $pointsToAdd = (int)round($price);
    $stmt3 = $conn->prepare("
        UPDATE lawyer
        SET Points = Points + ?
        WHERE LawyerID = ?
    ");
    $stmt3->bind_param("ii", $pointsToAdd, $lawyerId);
    $stmt3->execute();
    $stmt3->close();

    // 4) تحديث التايم سلوت إلى محجوز بدل الحذف
    $stmt4 = $conn->prepare("
        UPDATE timeslot
        SET is_booked = 1
        WHERE id = ?
    ");
    $stmt4->bind_param("i", $timeslotId);
    $stmt4->execute();
    $stmt4->close();

    // إنهاء العملية
    $conn->commit();

    echo json_encode([
        "success" => true,
        "appointment_id" => $appointmentId
    ], JSON_UNESCAPED_UNICODE);

} catch (Exception $e) {
    $conn->rollback();
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "message" => "خطأ في قاعدة البيانات: " . $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}

$conn->close();
?>
