<?php
require_once __DIR__ . '/config.php';

// رؤوس تسمح لتطبيق Flutter يقرأ الـ API
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json; charset=utf-8');

/*
  نرجّع آخر 10 محامين حالتهم Approved
  + نحسب التقييم من متوسط feedback.Rate
*/
$sql = "
SELECT
  l.LawyerID,
  l.FullName,
  l.LawyerPhoto,
  l.Status,
  IFNULL(ROUND(AVG(f.Rate), 1), 0) AS Rating   -- ← التقييم من feedback
FROM lawyer l
LEFT JOIN feedback f ON f.LawyerID = l.LawyerID
WHERE l.Status = 'Approved'
GROUP BY l.LawyerID, l.FullName, l.LawyerPhoto, l.Status
ORDER BY Rating DESC, l.LawyerID DESC
LIMIT 10
";

try {
  $stmt = $pdo->query($sql);
  $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

  // (اختياري) لو تخزّنين الصورة كمسار نسبي 'uploads/...'
  // نكمّلها إلى رابط كامل علشان Flutter يعرضها مباشرة
  // عدّلي base حسب مسار مجلد الـ API عندك
  /*
  $base = (isset($_SERVER['HTTP_HOST']) ? "http://{$_SERVER['HTTP_HOST']}" : "") . "/mujeer_api/";
  foreach ($rows as &$r) {
    if (!empty($r['LawyerPhoto']) && str_starts_with($r['LawyerPhoto'], 'uploads/')) {
      $r['LawyerPhoto'] = $base . $r['LawyerPhoto'];
    }
  }
  */

  echo json_encode(['ok' => true, 'data' => $rows], JSON_UNESCAPED_UNICODE);
} catch (Exception $e) {
  http_response_code(500);
  echo json_encode(['ok' => false, 'error' => $e->getMessage()], JSON_UNESCAPED_UNICODE);
}
