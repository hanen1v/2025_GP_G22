<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

error_reporting(E_ALL);
ini_set('display_errors', 1);

require_once 'config.php';

$raw  = file_get_contents("php://input");
$data = json_decode($raw, true);

if ($data === null || !isset($data['userId']) || !isset($data['userType'])) {
    echo json_encode([
        "success" => false,
        "message" => "userId أو userType مفقود"
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

$userId   = (int)$data['userId'];
$userType = strtolower(trim($data['userType']));

$table = null;
$idCol = null;

if ($userType === 'client') {
    $table = 'client';
    $idCol = 'ClientID';
} elseif ($userType === 'lawyer') {
    $table = 'lawyer';
    $idCol = 'LawyerID';
} else {
    echo json_encode([
        "success" => false,
        "message" => "Invalid userType"
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

$sql = "";
if ($userType === 'client') {
    $sql = "
        SELECT 
            ClientID   AS UserID,
            FullName,
            Username,
            PhoneNumber,
            Points,
            'client'   AS UserType
        FROM client
        WHERE ClientID = ?
        LIMIT 1
    ";
} else { // lawyer
    $sql = "
        SELECT 
            LawyerID   AS UserID,
            FullName,
            Username,
            PhoneNumber,
            Points,
            Status,
            YearsOfExp,
            MainSpecialization,
            FSubSpecialization,
            SSubSpecialization,
            EducationQualification,
            AcademicMajor,
            LawyerPhoto,
            'lawyer'   AS UserType
        FROM lawyer
        WHERE LawyerID = ?
        LIMIT 1
    ";
}

$stmt = $conn->prepare($sql);
if (!$stmt) {
    echo json_encode([
        "success" => false,
        "message" => "Prepare failed: " . $conn->error
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

$stmt->bind_param("i", $userId);
$stmt->execute();
$res = $stmt->get_result();

if (!$res || $res->num_rows === 0) {
    echo json_encode([
        "success" => false,
        "message" => "User not found"
    ], JSON_UNESCAPED_UNICODE);
    $stmt->close();
    $conn->close();
    exit;
}

$user = $res->fetch_assoc();
$stmt->close();
$conn->close();

echo json_encode([
    "success" => true,
    "user"    => $user
], JSON_UNESCAPED_UNICODE);
