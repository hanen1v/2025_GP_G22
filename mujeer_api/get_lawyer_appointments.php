<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

error_reporting(E_ALL);
ini_set('display_errors', 1);

require_once 'config.php';

// التوقيت: الرياض
date_default_timezone_set('Asia/Riyadh');

// قراءة JSON في الطلب
$raw = file_get_contents("php://input");
$data = json_decode($raw, true);

if ($data === null || !isset($data['lawyerId'])) {
    echo json_encode([
        "success" => false,
        "message" => "lawyerId مفقود"
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

$lawyerId = (int)$data['lawyerId'];

// جلب مواعيد المحامي
$sql = "
    SELECT
        a.AppointmentID,
        a.LawyerID,
        a.ClientID,
        a.DateTime,
        a.Status,
        c.FullName AS ClientName,

        -- نوع الخدمة
        CASE
            WHEN con.AppointmentID IS NOT NULL THEN 'consultation'
            WHEN cr.AppointmentID  IS NOT NULL THEN 'contract_review'
            ELSE NULL
        END AS consultation_type,

        -- التفاصيل
        COALESCE(con.Details, cr.Details) AS details,

        -- الملف
        COALESCE(con.File, cr.File) AS file

    FROM appointment a
    JOIN client c ON c.ClientID = a.ClientID

    LEFT JOIN consultation   con ON con.AppointmentID = a.AppointmentID
    LEFT JOIN contractreview cr  ON cr.AppointmentID = a.AppointmentID

    WHERE a.LawyerID = ?
    ORDER BY a.DateTime DESC
";

$stmt = $conn->prepare($sql);
if (!$stmt) {
    echo json_encode([
        "success" => false,
        "message" => "DB Error: " . $conn->error
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

$stmt->bind_param("i", $lawyerId);
$stmt->execute();
$result = $stmt->get_result();

$appointments = [];
$now = new DateTime();

// ستايتمنت لتحديث الحالة عند الحاجة
$updateStmt = $conn->prepare("UPDATE appointment SET Status = ? WHERE AppointmentID = ?");

while ($row = $result->fetch_assoc()) {

    $currentStatus = $row['Status'];

    if (!empty($row['DateTime']) && $currentStatus !== 'Cancelled') {

        try {
            $start = new DateTime($row['DateTime']);
            $end = clone $start;
            $end->modify('+1 hour'); // مدة الاستشارة ساعة واحدة

            if ($now < $start) {
                $computedStatus = 'Upcoming';
            } elseif ($now >= $start && $now <= $end) {
                $computedStatus = 'Active';
            } else {
                $computedStatus = 'Past';
            }

            // تحديث الحالة بالداتابيس لو تغيّرت
            if ($computedStatus !== $currentStatus) {
                if ($updateStmt) {
                    $updateStmt->bind_param("si", $computedStatus, $row['AppointmentID']);
                    $updateStmt->execute();
                }
                $row['Status'] = $computedStatus;
            }

        } catch (Exception $e) {
            // لو حصل خطأ بالتاريخ نتجاوز
        }
    }

    $appointments[] = $row;
}

if ($updateStmt) $updateStmt->close();
$stmt->close();
$conn->close();

echo json_encode([
    "success"      => true,
    "appointments" => $appointments
], JSON_UNESCAPED_UNICODE);
