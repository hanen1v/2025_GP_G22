<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

error_reporting(E_ALL);
ini_set('display_errors', 1);

require_once 'config.php';

$raw  = file_get_contents("php://input");
$data = json_decode($raw, true);

if ($data === null || !isset($data['appointmentId'])) {
    echo json_encode([
        "success" => false,
        "message" => "appointmentId مفقود"
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

$appointmentId = (int)$data['appointmentId'];

try {
    // نبدأ Transaction عشان كل العمليات تصير مع بعض
    $conn->begin_transaction();

    // 1) نجيب بيانات الموعد أولاً
    $sql = "
        SELECT 
            AppointmentID,
            LawyerID,
            Price,
            timeslot_id,
            DateTime,
            Status
        FROM appointment
        WHERE AppointmentID = ?
        LIMIT 1
    ";
    $stmt = $conn->prepare($sql);
    if (!$stmt) {
        throw new Exception("DB Error (prepare select): " . $conn->error);
    }

    $stmt->bind_param("i", $appointmentId);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows === 0) {
        throw new Exception("الموعد غير موجود");
    }

    $row        = $result->fetch_assoc();
    $lawyerId   = (int)$row['LawyerID'];
    $price      = $row['Price'] !== null ? (float)$row['Price'] : 0.0;
    $timeslotId = $row['timeslot_id'] !== null ? (int)$row['timeslot_id'] : 0;
    $status     = $row['Status'];
    $dateTimeStr= $row['DateTime'];

    $stmt->close();

    // نتأكد أن حالته Upcoming
    if ($status !== 'Upcoming') {
        throw new Exception("لا يمكن إلغاء هذا الموعد (حالته ليست Upcoming)");
    }

    // نحسب هل وقت الموعد لسه ما عدا
    $now      = new DateTime();              // وقت السيرفر الحالي
    $apptTime = new DateTime($dateTimeStr);  // وقت الموعد من الداتابيس
    $canFreeTimeslot = ($timeslotId > 0 && $apptTime > $now);

    // 2) إذا وقت الموعد ما عدا نرجع الـ timeslot متاح (is_booked = 0)
    if ($canFreeTimeslot) {
        $sqlTs = "UPDATE timeslot SET is_booked = 0 WHERE id = ? LIMIT 1";
        $stmtTs = $conn->prepare($sqlTs);
        if (!$stmtTs) {
            throw new Exception("DB Error (prepare timeslot): " . $conn->error);
        }
        $stmtTs->bind_param("i", $timeslotId);
        $stmtTs->execute();
        $stmtTs->close();
    }

    // 3) نضيف السعر كنقاط للمحامي (غيّري اسم العمود points إذا مختلف)
    if ($price > 0 && $lawyerId > 0) {
        $sqlLawyer = "UPDATE lawyer SET points = points + ? WHERE LawyerID = ? LIMIT 1";
        $stmtL = $conn->prepare($sqlLawyer);
        if (!$stmtL) {
            throw new Exception("DB Error (prepare lawyer): " . $conn->error);
        }
        $stmtL->bind_param("di", $price, $lawyerId);
        $stmtL->execute();
        $stmtL->close();
    }

    // 4) نحذف الموعد نفسه (لسه شرطه Upcoming)
    $sqlDel = "
        DELETE FROM appointment
        WHERE AppointmentID = ?
          AND Status = 'Upcoming'
        LIMIT 1
    ";
    $stmtDel = $conn->prepare($sqlDel);
    if (!$stmtDel) {
        throw new Exception("DB Error (prepare delete): " . $conn->error);
    }
    $stmtDel->bind_param("i", $appointmentId);
    $stmtDel->execute();

    if ($stmtDel->affected_rows <= 0) {
        throw new Exception("لم يتم إلغاء الموعد (قد يكون تم تعديله من قبل)");
    }

    $stmtDel->close();

    // كل شيء تمام → نعمل COMMIT
    $conn->commit();

    echo json_encode([
        "success" => true,
        "message" => "تم إلغاء الموعد بنجاح، وتحديث التوقيت والنقاط"
    ], JSON_UNESCAPED_UNICODE);

} catch (Exception $e) {
    // لو صار أي خطأ نرجّع كل شيء
    if ($conn->errno === 0) {
        // لو الترانزكشن شغّال نعمل rollback
        $conn->rollback();
    }

    echo json_encode([
        "success" => false,
        "message" => $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}

$conn->close();
