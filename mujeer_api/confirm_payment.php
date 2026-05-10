<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

require_once __DIR__ . '/config.php';

header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

$lawyerId    = isset($_POST['lawyer_id']) ? intval($_POST['lawyer_id']) : 0;
$clientId    = isset($_POST['client_id']) ? intval($_POST['client_id']) : 0;
$timeslotId  = isset($_POST['timeslot_id']) ? intval($_POST['timeslot_id']) : 0;
$price       = isset($_POST['price']) ? floatval($_POST['price']) : 0;
$details     = isset($_POST['details']) ? trim($_POST['details']) : '';
$fileName    = isset($_POST['file_name']) ? trim($_POST['file_name']) : null;
$requestType = isset($_POST['request_type']) ? $_POST['request_type'] : 'consultation';

if ($lawyerId == 0 || $clientId == 0 || $timeslotId == 0 || $price <= 0) {
    echo json_encode([
        "success" => false,
        "message" => "بيانات أساسية ناقصة"
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

if ($requestType === 'consultation' && $details === '') {
    echo json_encode([
        "success" => false,
        "message" => "يجب إدخال تفاصيل الاستشارة"
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

if ($requestType === 'contractReview' && ($fileName === null || $fileName === '')) {
    echo json_encode([
        "success" => false,
        "message" => "يجب إرفاق ملف لمراجعة العقد"
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

try {
    $conn->begin_transaction();

    $slotSql = "SELECT `time` FROM timeslot WHERE id = ? AND is_booked = 0";
    $slotStmt = $conn->prepare($slotSql);
    if (!$slotStmt) {
        throw new Exception("فشل تجهيز استعلام التايم سلوت: " . $conn->error);
    }
    $slotStmt->bind_param("i", $timeslotId);
    $slotStmt->execute();
    $slotRes = $slotStmt->get_result();

    if ($slotRes->num_rows === 0) {
        throw new Exception("الوقت المحدد غير متاح أو غير موجود");
    }

    $slotRow = $slotRes->fetch_assoc();
    $slotDateTime = $slotRow['time'];
    $slotStmt->close();

    $stmt = $conn->prepare("
        INSERT INTO appointment (LawyerID, ClientID, DateTime, Status, Price, timeslot_id)
        VALUES (?, ?, ?, 'Upcoming', ?, ?)
    ");
    if (!$stmt) {
        throw new Exception("فشل تجهيز استعلام إنشاء الموعد: " . $conn->error);
    }
    $stmt->bind_param("iisdi", $lawyerId, $clientId, $slotDateTime, $price, $timeslotId);
    $stmt->execute();

    if ($stmt->affected_rows <= 0) {
        throw new Exception("فشل إنشاء الموعد");
    }

    $appointmentId = $stmt->insert_id;
    $stmt->close();

    if ($requestType === 'consultation') {

        $stmt2 = $conn->prepare("
            INSERT INTO consultation (AppointmentID, Details, File)
            VALUES (?, ?, ?)
        ");
        if (!$stmt2) {
            throw new Exception("فشل تجهيز استعلام الاستشارة: " . $conn->error);
        }

        $stmt2->bind_param("iss", $appointmentId, $details, $fileName);
        $stmt2->execute();
        $stmt2->close();

    } elseif ($requestType === 'contractReview') {

        $stmt2 = $conn->prepare("
            INSERT INTO contractreview (AppointmentID, Details, File)
            VALUES (?, ?, ?)
        ");
        if (!$stmt2) {
            throw new Exception("فشل تجهيز استعلام مراجعة العقد: " . $conn->error);
        }

        $stmt2->bind_param("iss", $appointmentId, $details, $fileName);
        $stmt2->execute();
        $stmt2->close();

    } else {
        throw new Exception("نوع الطلب غير معروف");
    }

    $pointsToAdd = (int)round($price);
    $stmt3 = $conn->prepare("
        UPDATE lawyer
        SET Points = Points + ?
        WHERE LawyerID = ?
    ");
    if (!$stmt3) {
        throw new Exception("فشل تجهيز استعلام النقاط: " . $conn->error);
    }
    $stmt3->bind_param("ii", $pointsToAdd, $lawyerId);
    $stmt3->execute();
    $stmt3->close();

    $stmt4 = $conn->prepare("
        UPDATE timeslot
        SET is_booked = 1
        WHERE id = ?
    ");
    if (!$stmt4) {
        throw new Exception("فشل تجهيز استعلام تحديث التايم سلوت: " . $conn->error);
    }
    $stmt4->bind_param("i", $timeslotId);
    $stmt4->execute();
    $stmt4->close();

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
