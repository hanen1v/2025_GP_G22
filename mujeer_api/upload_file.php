<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

function cloudinary_upload($tmpPath, $fileType, $fileName, $resourceType = 'image') {
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

if (isset($_FILES["file"])) {
    $ext          = strtolower(pathinfo($_FILES["file"]["name"], PATHINFO_EXTENSION));
    $originalName = basename($_FILES["file"]["name"]);
    $fileName     = time() . "_" . uniqid() . "." . $ext; // اسم رقمي قصير
    $resourceType = ($ext === 'pdf') ? 'raw' : 'image';

    $result = cloudinary_upload($_FILES["file"]["tmp_name"], $_FILES["file"]["type"], $fileName, $resourceType);

    if ($result["success"]) {
        $fileUrl = $result["url"];

        // ✅ Cloudinary يحذف الامتداد من ملفات raw — أضفه يدوياً
        if ($resourceType === 'raw' && substr($fileUrl, -strlen('.' . $ext)) !== '.' . $ext) {
            $fileUrl = $fileUrl . '.' . $ext;
        }

        echo json_encode([
            "success"   => true,
            "file_url"  => $fileUrl,
            "file_name" => $originalName, // الاسم الأصلي للعرض فقط
        ]);
    } else {
        echo json_encode(["success" => false, "error" => $result["error"]]);
    }
} else {
    echo json_encode(["success" => false]);
}
?>