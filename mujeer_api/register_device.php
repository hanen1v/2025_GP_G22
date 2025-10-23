<?php
require_once __DIR__ . '/config.php';
header('Content-Type: application/json; charset=utf-8');
error_reporting(E_ALL);
ini_set('display_errors', 1);
$input = json_decode(file_get_contents('php://input'), true) ?? [];
$admin_id  = isset($input['admin_id']) ? (int)$input['admin_id'] : 0;
$player_id = isset($input['player_id']) ? trim($input['player_id']) : '';

if ($admin_id <= 0 || $player_id === '') {
  http_response_code(400);
  echo json_encode(['ok' => false, 'message' => 'Missing admin_id or player_id']);
  exit;
}


$stmt = $conn->prepare("SELECT AdminID FROM admin WHERE AdminID = ?");
$stmt->bind_param("i", $admin_id);
$stmt->execute();
$stmt->store_result();
if ($stmt->num_rows === 0) {
  http_response_code(404);
  echo json_encode(['ok' => false, 'message' => 'Admin not found']);
  exit;
}
$stmt->close();

$insertSql = "INSERT INTO admin_devices (admin_id, player_id) VALUES (?, ?)
              ON DUPLICATE KEY UPDATE admin_id = VALUES(admin_id)";
$stmt2 = $conn->prepare($insertSql);
$stmt2->bind_param("is", $admin_id, $player_id);
$ok = $stmt2->execute();
if (!$ok) {
  http_response_code(500);
  echo json_encode(['ok' => false, 'message' => 'DB insert error', 'error' => $conn->error]);
  exit;
}
$stmt2->close();

echo json_encode(['ok' => true, 'admin_id' => $admin_id, 'player_id' => $player_id]);
