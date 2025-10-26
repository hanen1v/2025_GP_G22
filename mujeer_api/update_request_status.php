<?php
require_once __DIR__ . '/config.php';

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Content-Type: application/json; charset=utf-8');

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
    $pdo->beginTransaction();

    $stmt = $pdo->prepare("SELECT LawyerID, Status FROM Request WHERE RequestID = ? FOR UPDATE");
    $stmt->execute([$requestID]);
    $req = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$req) {
        $pdo->rollBack();
        http_response_code(404);
        echo json_encode(['ok' => false, 'message' => 'Request not found']);
        exit;
    }

    $lawyerID = (int)($req['LawyerID'] ?? 0);

    $stmt = $pdo->prepare("UPDATE Request SET Status = ? WHERE RequestID = ?");
    $stmt->execute([$newStatus, $requestID]);

    if ($lawyerID > 0) {
        $stmt = $pdo->prepare("UPDATE Lawyer SET Status = ? WHERE LawyerID = ?");
        $stmt->execute([$newStatus, $lawyerID]);
    }

    $pdo->commit();

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
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    http_response_code(500);
    echo json_encode([
        'ok'      => false,
        'message' => 'Failed to update status',
        'detail'  => $e->getMessage(),
    ], JSON_UNESCAPED_UNICODE);
}
