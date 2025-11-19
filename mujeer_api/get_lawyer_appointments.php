<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

error_reporting(E_ALL);
ini_set('display_errors', 1);

require_once 'config.php';

// نقرأ JSON من Flutter
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

/*
 * ✅ مهم:
 * عدّلي اسم جدول العميل وعمود الاسم حسب الداتا بيس عندك
 * مثلاً:
 *  - لو الجدول اسمه client والعمود FullName → زي ما هو
 *  - لو اسمه clients أو users أو clients_table غيريها هنا
 */

$sql = "
    SELECT
        a.AppointmentID,
        a.LawyerID,
        a.ClientID,
        a.DateTime,
        a.Status,
        c.FullName AS ClientName,

        -- ✅ نوع الاستشارة: من أي جدول أخذناها
        CASE
            WHEN con.AppointmentID IS NOT NULL THEN 'consultation'
            WHEN cr.AppointmentID  IS NOT NULL THEN 'contract_review'
            ELSE NULL
        END AS consultation_type,

        -- ✅ التفاصيل
        COALESCE(con.Details, cr.Details) AS details,

        -- ✅ الملف
        COALESCE(con.File, cr.File) AS file

    FROM appointment a
    JOIN client c ON c.ClientID = a.ClientID

    -- جدول الاستشارة القانونية
    LEFT JOIN consultation   con ON con.AppointmentID = a.AppointmentID

    -- جدول مراجعة العقد
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
while ($row = $result->fetch_assoc()) {
    $appointments[] = $row;
}

$stmt->close();
$conn->close();

echo json_encode([
    "success"      => true,
    "appointments" => $appointments
], JSON_UNESCAPED_UNICODE);

