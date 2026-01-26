<?php
require_once __DIR__ . '/config.php';

header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json; charset=utf-8');

$sql = "SELECT * FROM `Request` WHERE `Status` = 'Pending'";

try {
    // تنفيذ الاستعلام بـ MySQLi (باستخدام $conn القادم من config.php)
    $result = $conn->query($sql);
    if (!$result) {
        throw new Exception($conn->error);
    }

    $rows = [];
    while ($row = $result->fetch_assoc()) {
        $rows[] = $row;
    }
    $result->free();

    echo json_encode(['ok' => true, 'data' => $rows], JSON_UNESCAPED_UNICODE);
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode([
        'ok'    => false,
        'error' => 'DB query failed',
        'detail'=> $e->getMessage(),
    ], JSON_UNESCAPED_UNICODE);
}
