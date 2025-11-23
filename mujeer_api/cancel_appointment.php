<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

error_reporting(E_ALL);
ini_set('display_errors', 1);

require_once 'config.php';

$raw = file_get_contents("php://input");
$data = json_decode($raw, true);

if ($data === null || !isset($data['appointmentId'])) {
    echo json_encode([
        "success" => false,
        "message" => "appointmentId مفقود"
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

$appointmentId = (int)$data['appointmentId'];

// نحذف الموعد إذا كان لسا Upcoming
$sql = "DELETE FROM appointment 
        WHERE AppointmentID = ? 
          AND Status = 'Upcoming'
        LIMIT 1";

$stmt = $conn->prepare($sql);
if (!$stmt) {
    echo json_encode([
        "success" => false,
        "message" => "DB Error: " . $conn->error
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

$stmt->bind_param("i", $appointmentId);
$stmt->execute();

if ($stmt->affected_rows > 0) {
    echo json_encode([
        "success" => true,
        "message" => "تم إلغاء الموعد بنجاح"
    ], JSON_UNESCAPED_UNICODE);
} else {
    echo json_encode([
        "success" => false,
        "message" => "لا يمكن إلغاء هذا الموعد (ربما ليس Upcoming)"
    ], JSON_UNESCAPED_UNICODE);
}

$stmt->close();
$conn->close();

