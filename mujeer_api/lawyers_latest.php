<?php
require_once __DIR__ . '/config.php';

// رؤوس بسيطة تسمح للـ Flutter يقرأ من الـ API
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json; charset=utf-8');

/*
  نرجّع آخر 10 محامين حالتهم Approved
  + نحسب تقييم تقريبي من Points (أو اخليها 4.9 لو ما فيه نقاط)
*/
$sql = "SELECT LawyerID, FullName, LawyerPhoto, Points, Status
        FROM lawyer
        WHERE Status = 'Approved'
        ORDER BY LawyerID DESC
        LIMIT 10";

try {
  $stmt = $pdo->query($sql);
  $rows = $stmt->fetchAll();

  foreach ($rows as &$r) {
    $points = isset($r['Points']) ? (float)$r['Points'] : 0.0;
    $r['Rating'] = $points > 0 ? min(5.0, round($points / 20.0, 1)) : 4.9;
  }

  echo json_encode(['ok' => true, 'data' => $rows], JSON_UNESCAPED_UNICODE);
} catch (Exception $e) {
  http_response_code(500);
  echo json_encode(['ok' => false, 'error' => $e->getMessage()], JSON_UNESCAPED_UNICODE);
}
