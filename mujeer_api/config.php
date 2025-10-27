<?php
$DB_HOST = 'localhost';
$DB_PORT = '8889';
$DB_NAME = 'mujeer'; 
$DB_USER = 'root';
$DB_PASS = 'root';

define('ONESIGNAL_APP_ID', '52e7af05-5276-4ccd-9715-1cb9820f4361'); 
define('ONESIGNAL_REST_API_KEY', 'os_v2_app_klt26bksozgm3fyvds4yed2dmhuzz3i5bv6ezzmuayihpfhxtceboihpwwfdus5rmbk7nw2w3hfdz7zfbdpv24klni2tnjcc2vjmiry'); 

error_reporting(E_ALL);
ini_set('display_errors', 1);
// استخدمي mysqli بدل PDO
$conn = new mysqli($DB_HOST, $DB_USER, $DB_PASS, $DB_NAME, $DB_PORT);

if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'فشل الاتصال بقاعدة البيانات']);
    exit;
}

$conn->set_charset("utf8mb4");


// دالة إرسال الإشعار
function send_push(array $playerIds, string $title, string $body, array $data = []) {
  if (empty($playerIds)) return ['ok' => false, 'reason' => 'No players'];
    $payload = [
        'app_id' => ONESIGNAL_APP_ID,
        'include_player_ids' => array_values($playerIds),
        'headings' => ['ar' => $title, 'en' => $title], 
        'contents' => ['ar' => $body, 'en' => $body],   
        'data' => $data ?: ['type' => 'notification']
    ];

    error_log("Fixed Payload: " . json_encode($payload));

    $ch = curl_init();
    curl_setopt_array($ch, [
        CURLOPT_URL => 'https://onesignal.com/api/v1/notifications',
        CURLOPT_HTTPHEADER => [
            'Authorization: Bearer ' . ONESIGNAL_REST_API_KEY,
            'Content-Type: application/json; charset=utf-8'
        ],
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_POST => true,
        CURLOPT_POSTFIELDS => json_encode($payload, JSON_UNESCAPED_UNICODE),
        CURLOPT_TIMEOUT => 15,
        CURLOPT_SSL_VERIFYPEER => false,
        CURLOPT_SSL_VERIFYHOST => false,
    ]);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $error = curl_error($ch);
    curl_close($ch);

    error_log("OneSignal Response - HTTP: $httpCode");
    error_log("OneSignal Response Body: " . $response);

    if ($response === false) {
        return ['ok' => false, 'error' => $error, 'http_code' => $httpCode];
    }

    $result = json_decode($response, true);
    
    if ($httpCode === 400) {
        $errorMsg = "Bad Request - ";
        if (isset($result['errors'])) {
            $errorMsg .= implode(', ', $result['errors']);
        } else {
            $errorMsg .= "Check payload structure";
        }
        return ['ok' => false, 'error' => $errorMsg, 'http_code' => $httpCode, 'response' => $result];
    }
    
    if ($httpCode !== 200) {
        return ['ok' => false, 'error' => "HTTP Error: $httpCode", 'http_code' => $httpCode, 'response' => $result];
    }

    return ['ok' => true, 'response' => $result, 'http_code' => $httpCode];
}
