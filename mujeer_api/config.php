<?php
// إعدادات الاتصال بقاعدة mujeer على MAMP
$DB_HOST = 'localhost';
$DB_PORT = '8889';    // منفذ MySQL في MAMP
$DB_NAME = 'mujeer';
$DB_USER = 'root';
$DB_PASS = 'root';    // الافتراضي في MAMP

$dsn = "mysql:host=$DB_HOST;port=$DB_PORT;dbname=$DB_NAME;charset=utf8mb4";

try {
  $pdo = new PDO($dsn, $DB_USER, $DB_PASS, [
    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
  ]);
} catch (PDOException $e) {
  http_response_code(500);
  header('Content-Type: application/json; charset=utf-8');
  echo json_encode(['ok' => false, 'error' => 'DB connection failed', 'detail' => $e->getMessage()], JSON_UNESCAPED_UNICODE);
  exit;
}
