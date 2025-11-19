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

if ($data === null || !isset($data['clientId'])) {
    echo json_encode([
        "success" => false,
        "message" => "clientId مفقود"
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

$clientId = (int)$data['clientId'];

// نجيب كل المواعيد + هل هذا العميل أعطى أي فيدباك لهذا المحامي من قبل
$sql = "
    SELECT 
        a.AppointmentID,
        a.LawyerID,
        a.ClientID,
        a.DateTime,
        a.Status,
        a.Price,
        a.timeslot_id,
        l.FullName AS LawyerName,
        l.LawyerPhoto,
        EXISTS (
            SELECT 1 
            FROM feedback f 
            WHERE f.LawyerID = a.LawyerID 
              AND f.ClientID = a.ClientID
        ) AS HasFeedback
    FROM appointment a
    JOIN lawyer l ON l.LawyerID = a.LawyerID
    WHERE a.ClientID = ?
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

$stmt->bind_param("i", $clientId);
$stmt->execute();
$result = $stmt->get_result();

$appointments = [];
while ($row = $result->fetch_assoc()) {
    $row['HasFeedback'] = (int)$row['HasFeedback']; // 0 أو 1
    $appointments[] = $row;
}

$stmt->close();
$conn->close();

echo json_encode([
    "success"      => true,
    "appointments" => $appointments
], JSON_UNESCAPED_UNICODE);
