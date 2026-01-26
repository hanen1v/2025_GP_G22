<?php
require_once __DIR__ . '/config.php'; 
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Content-Type: application/json; charset=utf-8');
error_reporting(E_ALL);
ini_set('display_errors', 1);


if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['ok' => false, 'message' => 'Method Not Allowed']);
    exit;
}

$payload   = json_decode(file_get_contents('php://input'), true) ?? [];
$requestID = isset($payload['RequestID']) ? (int)$payload['RequestID'] : 0;
$newStatus = isset($payload['Status']) ? trim($payload['Status']) : '';

$allowed = ['Approved', 'Rejected'];
if ($requestID <= 0 || !in_array($newStatus, $allowed, true)) {
    http_response_code(400);
    echo json_encode(['ok' => false, 'message' => 'Invalid RequestID or Status']);
    exit;
}

try {
    $conn->begin_transaction();

    $stmt = $conn->prepare("SELECT LawyerID, Status FROM Request WHERE RequestID = ? FOR UPDATE");
    $stmt->bind_param("i", $requestID);
    $stmt->execute();
    $req = $stmt->get_result()->fetch_assoc();

    if (!$req) {
        $conn->rollback();
        http_response_code(404);
        echo json_encode(['ok' => false, 'message' => 'Request not found']);
        exit;
    }

    $lawyerID = (int)($req['LawyerID'] ?? 0);

    $stmt = $conn->prepare("UPDATE Request SET Status = ? WHERE RequestID = ?");
    $stmt->bind_param("si", $newStatus, $requestID);
    $stmt->execute();

    if ($lawyerID > 0) {
        $stmt = $conn->prepare("UPDATE Lawyer SET Status = ? WHERE LawyerID = ?");
        $stmt->bind_param("si", $newStatus, $lawyerID);
        $stmt->execute();
    }



    $conn->commit();

    echo json_encode([
        'ok'      => true,
        'message' => 'Status updated successfully',
        'data'    => [
            'RequestID' => $requestID,
            'LawyerID'  => $lawyerID ?: null,
            'Status'    => $newStatus,
        ],
    ], JSON_UNESCAPED_UNICODE);

} catch (Throwable $e) {
    if ($conn && $conn->errno) {
        $conn->rollback();
    }
    http_response_code(500);
    echo json_encode([
        'ok'      => false,
        'message' => 'Failed to update status',
        'detail'  => $e->getMessage(),     ], JSON_UNESCAPED_UNICODE);
} finally {
    if ($conn) { $conn->close(); }
}
