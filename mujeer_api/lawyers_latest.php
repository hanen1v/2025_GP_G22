<?php
require_once __DIR__ . '/config.php';

header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json; charset=utf-8');

$sql = "
  SELECT
    l.LawyerID,
    l.FullName,
    l.LawyerPhoto,
    l.Status,
    IFNULL(ROUND(AVG(f.Rate), 1), 0) AS Rating
  FROM lawyer l
  LEFT JOIN feedback f ON f.LawyerID = l.LawyerID
  WHERE l.Status = 'Approved'
  GROUP BY l.LawyerID, l.FullName, l.LawyerPhoto, l.Status
  ORDER BY Rating DESC, l.LawyerID DESC
  LIMIT 10
";

try {
  $res = $conn->query($sql);
  if (!$res) {
    http_response_code(500);
    echo json_encode(['ok' => false, 'error' => $conn->error], JSON_UNESCAPED_UNICODE);
    exit;
  }

  $rows = [];
  while ($r = $res->fetch_assoc()) {
    $rows[] = $r;
  }

  echo json_encode(['ok' => true, 'data' => $rows], JSON_UNESCAPED_UNICODE);
} catch (Throwable $e) {
  http_response_code(500);
  echo json_encode(['ok' => false, 'error' => $e->getMessage()], JSON_UNESCAPED_UNICODE);
}
