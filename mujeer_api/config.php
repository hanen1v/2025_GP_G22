<?php
$DB_HOST = getenv('MYSQLHOST') ?: getenv('DB_HOST') ?: 'localhost';
$DB_PORT = getenv('MYSQLPORT') ?: getenv('DB_PORT') ?: '3306';
$DB_NAME = getenv('MYSQLDATABASE') ?: getenv('DB_NAME') ?: 'railway';
$DB_USER = getenv('MYSQLUSER') ?: getenv('DB_USER') ?: 'root';
$DB_PASS = getenv('MYSQLPASSWORD') ?: getenv('DB_PASS') ?: '';

define('ONESIGNAL_APP_ID',       getenv('ONESIGNAL_APP_ID')       ?: '');
define('ONESIGNAL_REST_API_KEY', getenv('ONESIGNAL_REST_API_KEY') ?: '');
define('OPENAI_API_KEY',         getenv('OPENAI_API_KEY')         ?: '');

error_reporting(E_ALL);
ini_set('display_errors', 0);

$conn = new mysqli($DB_HOST, $DB_USER, $DB_PASS, $DB_NAME, (int)$DB_PORT);

if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'فشل الاتصال بقاعدة البيانات']);
    exit;
}

$conn->set_charset("utf8mb4");

function send_push(array $playerIds, string $title, string $body, array $data = []) {
    if (empty($playerIds)) return ['ok' => false, 'reason' => 'No players'];
    $payload = [
        'app_id'             => ONESIGNAL_APP_ID,
        'include_player_ids' => array_values($playerIds),
        'headings'           => ['ar' => $title, 'en' => $title],
        'contents'           => ['ar' => $body,  'en' => $body],
        'data'               => $data ?: ['type' => 'notification'],
    ];
    $ch = curl_init();
    curl_setopt_array($ch, [
        CURLOPT_URL            => 'https://onesignal.com/api/v1/notifications',
        CURLOPT_HTTPHEADER     => [
            'Authorization: Bearer ' . ONESIGNAL_REST_API_KEY,
            'Content-Type: application/json; charset=utf-8',
        ],
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_POST           => true,
        CURLOPT_POSTFIELDS     => json_encode($payload, JSON_UNESCAPED_UNICODE),
        CURLOPT_TIMEOUT        => 3,
        CURLOPT_SSL_VERIFYPEER => false,
    ]);
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    if (!$response) return ['ok' => false];
    $result = json_decode($response, true);
    return $httpCode === 200 ? ['ok' => true, 'response' => $result] : ['ok' => false, 'error' => "HTTP $httpCode"];
}