<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type");

error_reporting(E_ALL);
ini_set('display_errors', 0);

// Cloudinary credentials from environment variables
$CLOUD_NAME = getenv('CLOUDINARY_CLOUD_NAME') ?: 'dmhrba99m';
$API_KEY    = getenv('CLOUDINARY_API_KEY')    ?: '696554864561483';
$API_SECRET = getenv('CLOUDINARY_API_SECRET') ?: '';

if (
    (isset($_FILES['file']) || isset($_FILES['license_file']) || isset($_FILES['profile_image']))
    && isset($_POST['fileName'])
) {
    $uploadedFile = $_FILES['file']
        ?? $_FILES['license_file']
        ?? $_FILES['profile_image'];

    $fileName = $_POST['fileName'];
    $tmpPath   = $uploadedFile['tmp_name'];

    // رفع على Cloudinary
    $timestamp = time();
    $signature = sha1("public_id=$fileName&timestamp=$timestamp" . $API_SECRET);

    $ch = curl_init();
    curl_setopt_array($ch, [
        CURLOPT_URL            => "https://api.cloudinary.com/v1_1/$CLOUD_NAME/auto/upload",
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_POST           => true,
        CURLOPT_POSTFIELDS     => [
            'file'      => new CURLFile($tmpPath, $uploadedFile['type'], $fileName),
            'public_id' => $fileName,
            'timestamp' => $timestamp,
            'api_key'   => $API_KEY,
            'signature' => $signature,
        ],
    ]);

    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    $result = json_decode($response, true);

    if ($httpCode === 200 && isset($result['secure_url'])) {
        echo json_encode([
            "success" => true,
            "message" => "تم رفع الملف بنجاح",
            "url"     => $result['secure_url'],
            "fileName" => $fileName,
        ]);
    } else {
        echo json_encode([
            "success" => false,
            "message" => "فشل رفع الملف على Cloudinary",
            "error"   => $result['error']['message'] ?? 'Unknown error',
        ]);
    }
} else {
    echo json_encode(["success" => false, "message" => "لم يتم استلام الملف"]);
}
?>