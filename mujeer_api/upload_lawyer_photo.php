<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

error_reporting(E_ALL);
ini_set('display_errors', 1);

require_once __DIR__ . '/config.php';

function cloudinary_upload($tmpPath, $fileType, $fileName) {
    $CLOUD_NAME = getenv("CLOUDINARY_CLOUD_NAME") ?: "dmhrba99m";
    $API_KEY    = getenv("CLOUDINARY_API_KEY")    ?: "696554864561483";
    $API_SECRET = getenv("CLOUDINARY_API_SECRET") ?: "";
    $timestamp  = time();
    $signature  = sha1("public_id=$fileName&timestamp=$timestamp" . $API_SECRET);
    $ch = curl_init();
    curl_setopt_array($ch, [
        CURLOPT_URL            => "https://api.cloudinary.com/v1_1/$CLOUD_NAME/auto/upload",
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_POST           => true,
        CURLOPT_POSTFIELDS     => [
            "file"      => new CURLFile($tmpPath, $fileType, $fileName),
            "public_id" => $fileName,
            "timestamp" => $timestamp,
            "api_key"   => $API_KEY,
            "signature" => $signature,
        ],
    ]);
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    $result = json_decode($response, true);
    if ($httpCode === 200 && isset($result["secure_url"])) {
        return ["success" => true, "url" => $result["secure_url"]];
    }
    return ["success" => false, "error" => $result["error"]["message"] ?? "Upload failed"];
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(["success" => false, "message" => "Invalid method"]);
    exit;
}

$lawyerId = isset($_POST['lawyer_id']) ? (int)$_POST['lawyer_id'] : 0;
if ($lawyerId <= 0) {
    echo json_encode(["success" => false, "message" => "Missing lawyer_id"]);
    exit;
}

if (!isset($_FILES['photo']) || $_FILES['photo']['error'] !== UPLOAD_ERR_OK) {
    echo json_encode(["success" => false, "message" => "No photo uploaded"]);
    exit;
}

$ext = strtolower(pathinfo($_FILES['photo']['name'], PATHINFO_EXTENSION));
if (!in_array($ext, ['jpg','jpeg','png'])) {
    echo json_encode(["success" => false, "message" => "Invalid file type"]);
    exit;
}

$fileName = 'lawyer_' . $lawyerId . '_' . time();
$result   = cloudinary_upload($_FILES['photo']['tmp_name'], $_FILES['photo']['type'], $fileName);

if (!$result["success"]) {
    echo json_encode(["success" => false, "message" => $result["error"]]);
    exit;
}

$photoUrl = $result["url"];

$stmt = $conn->prepare("UPDATE lawyer SET LawyerPhoto = ? WHERE LawyerID = ? LIMIT 1");
$stmt->bind_param("si", $photoUrl, $lawyerId);

if ($stmt->execute()) {
    echo json_encode([
        "success"  => true,
        "message"  => "تم تحديث الصورة بنجاح",
        "fileName" => $photoUrl,
    ], JSON_UNESCAPED_UNICODE);
} else {
    echo json_encode(["success" => false, "message" => "Update failed"]);
}
?>