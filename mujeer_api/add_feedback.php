<?php
require_once __DIR__ . '/config.php'; 
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Headers: Content-Type');
header('Content-Type: application/json; charset=utf-8');

$raw = file_get_contents('php://input');
$data = json_decode($raw, true);

if (!is_array($data) 
    || !isset($data['lawyer_id']) 
    || !isset($data['client_id']) 
    || !isset($data['rating']) 
    || !isset($data['comment'])) {

    http_response_code(400);
    echo json_encode(['ok' => false, 'message' => 'Missing required fields'], JSON_UNESCAPED_UNICODE);
    exit;
}

$lawyerId = intval($data['lawyer_id']);
$clientId = intval($data['client_id']);
$rating   = intval($data['rating']);
$comment  = trim($data['comment']);
$dateGiven = date('Y-m-d H:i:s'); 
//check rating
if ($rating < 1 || $rating > 5) {
    http_response_code(422);
    echo json_encode(['ok' => false, 'message' => 'Invalid rating value'], JSON_UNESCAPED_UNICODE);
    exit;
}

try {
    // check lawyer
    $checkLawyer = $conn->prepare("SELECT LawyerID FROM lawyer WHERE LawyerID = ?");
    $checkLawyer->bind_param("i", $lawyerId);
    $checkLawyer->execute();
    $resultLawyer = $checkLawyer->get_result();

    if ($resultLawyer->num_rows === 0) {
        http_response_code(404);
        echo json_encode(['ok' => false, 'message' => 'Lawyer not found'], JSON_UNESCAPED_UNICODE);
        exit;
    }

    // check client
    $checkClient = $conn->prepare("SELECT ClientID FROM client WHERE ClientID = ?");
    $checkClient->bind_param("i", $clientId);
    $checkClient->execute();
    $resultClient = $checkClient->get_result();

    if ($resultClient->num_rows === 0) {
        http_response_code(404);
        echo json_encode(['ok' => false, 'message' => 'Client not found'], JSON_UNESCAPED_UNICODE);
        exit;
    }

    // insert feedback
    $insert = $conn->prepare("
        INSERT INTO feedback (LawyerID, ClientID, Rate, Review, DateGiven)
        VALUES (?, ?, ?, ?, ?)
    ");
    $insert->bind_param("iiiss", $lawyerId, $clientId, $rating, $comment, $dateGiven);
    $insert->execute();

    if ($insert->affected_rows > 0) {
        echo json_encode(['ok' => true], JSON_UNESCAPED_UNICODE);
    } else {
        http_response_code(500);
        echo json_encode(['ok' => false, 'message' => 'Insert failed'], JSON_UNESCAPED_UNICODE);
    }

} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode([
        'ok' => false,
        'message' => 'Server error',
        'detail' => $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}

$conn->close();
?>
