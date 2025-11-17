<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);
require_once __DIR__ . '/config.php';

header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

if (!isset($_GET['lawyer_id'])) {
    echo json_encode(["success" => false, "message" => "No lawyer ID provided"]);
    exit;
}

$lawyerId = intval($_GET['lawyer_id']);


$sql = "SELECT id, day, time 
        FROM timeslot 
        WHERE lawyer_id = ? AND is_booked = 0
        ORDER BY 
            FIELD(day, 'sunday','monday','tuesday','wednesday','thursday','friday','saturday'),
            time ASC";

$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $lawyerId);
$stmt->execute();
$result = $stmt->get_result();

$slots = [];

while ($row = $result->fetch_assoc()) {
    $slots[] = [
        "id" => $row["id"],
        "day" => $row["day"],
        "time" => $row["time"]
    ];
}

echo json_encode($slots, JSON_UNESCAPED_UNICODE);
?>
