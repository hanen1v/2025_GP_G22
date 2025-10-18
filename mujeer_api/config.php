<?php
$DB_HOST = 'localhost';
$DB_PORT = '8889';
$DB_NAME = 'mujeer'; 
$DB_USER = 'root';
$DB_PASS = 'root';

// استخدمي mysqli بدل PDO
$conn = new mysqli($DB_HOST, $DB_USER, $DB_PASS, $DB_NAME, $DB_PORT);

if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'فشل الاتصال بقاعدة البيانات']);
    exit;
}

$conn->set_charset("utf8mb4");
?>