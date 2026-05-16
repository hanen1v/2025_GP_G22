<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

error_reporting(E_ALL);
ini_set('display_errors', 0);

include 'config.php';

function cloudinary_upload($tmpPath, $fileType, $fileName, $resourceType = 'raw') {
    $CLOUD_NAME = getenv("CLOUDINARY_CLOUD_NAME") ?: "dmhrba99m";
    $API_KEY    = getenv("CLOUDINARY_API_KEY")    ?: "696554864561483";
    $API_SECRET = getenv("CLOUDINARY_API_SECRET") ?: "";
    $timestamp  = time();
    $signature  = sha1("public_id=$fileName&timestamp=$timestamp" . $API_SECRET);

    $ch = curl_init();
    curl_setopt_array($ch, [
        CURLOPT_URL            => "https://api.cloudinary.com/v1_1/$CLOUD_NAME/$resourceType/upload",
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

// ── رفع ملف الرخصة (PDF) ──
if (isset($_FILES['license_file']) && $_FILES['license_file']['error'] === UPLOAD_ERR_OK) {
    $fileName = $_POST['fileName'] ?? ('license_' . time());
    // أزل .pdf من الاسم لأن Cloudinary يضيفه تلقائياً
    $fileName = $fileName;

    $result = cloudinary_upload(
        $_FILES['license_file']['tmp_name'],
        $_FILES['license_file']['type'],
        $fileName,
        'raw'  // ← مهم للـ PDF
    );

    if ($result['success']) {
        // حدّث قاعدة البيانات بالـ URL الجديد
        $url = $result['url'];
        $stmt = $conn->prepare("UPDATE lawyer SET LicenseFile = ? WHERE LicenseFile LIKE ?");
        $likePattern = "%$fileName%";
        $stmt->bind_param("ss", $url, $likePattern);
        $stmt->execute();

        // كمان حدّث جدول Request
        $stmt2 = $conn->prepare("UPDATE Request SET LawyerLicense = ? WHERE LawyerLicense LIKE ?");
        $stmt2->bind_param("ss", $url, $likePattern);
        $stmt2->execute();

        echo json_encode(["success" => true, "url" => $url]);
    } else {
        echo json_encode(["success" => false, "message" => $result['error']]);
    }
    exit;
}

echo json_encode(["success" => false, "message" => "لم يتم استلام الملف"]);
?>