<?php
require_once __DIR__ . '/config.php';

header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json; charset=utf-8');

// استلام LawyerID من POST أو GET
$lawyerId = (int)($_POST['lawyer_id'] ?? $_GET['lawyer_id'] ?? 0);
if (!$lawyerId) {
  echo json_encode(['ok' => false, 'error' => 'missing_id'], JSON_UNESCAPED_UNICODE);
  exit;
}

// جلب الحالة من جدول lawyer
$sql = "SELECT TRIM(Status) AS Status FROM lawyer WHERE LawyerID = $lawyerId LIMIT 1";
$res = $conn->query($sql);
if (!$res || $res->num_rows === 0) {
  echo json_encode(['ok' => false, 'error' => 'not_found'], JSON_UNESCAPED_UNICODE);
  exit;
}

$row = $res->fetch_assoc();
$raw = strtolower($row['Status'] ?? '');

// تطبيع القيم
if ($raw === 'approved') $status = 'Approved';
else if ($raw === 'rejected') $status = 'Rejected';
else $status = 'Pending';

echo json_encode(['ok' => true, 'status' => $status], JSON_UNESCAPED_UNICODE);
