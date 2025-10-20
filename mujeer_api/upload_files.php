
<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type");

error_reporting(E_ALL);
ini_set('display_errors', 1);


$uploadDir = 'C:/mamp/htdocs/mujeer_api/uploads/';

// تأكد من وجود المجلد
if (!file_exists($uploadDir)) {
    mkdir($uploadDir, 0777, true);
}

error_log("=== FILE UPLOAD ATTEMPT ===");
error_log("Upload directory: " . $uploadDir);

if(isset($_FILES['file']) && isset($_POST['fileName'])) {
    $uploadedFile = $_FILES['file'];
    $fileName = $_POST['fileName'];
    
    $targetPath = $uploadDir . $fileName;
    
    error_log("File name: " . $fileName);
    error_log("Temp path: " . $uploadedFile['tmp_name']);
    error_log("Target path: " . $targetPath);
    error_log("File size: " . $uploadedFile['size']);
    error_log("File error: " . $uploadedFile['error']);
    
    if(move_uploaded_file($uploadedFile['tmp_name'], $targetPath)) {
        error_log("SUCCESS: File uploaded successfully");
        echo json_encode(["success" => true, "message" => "تم رفع الملف بنجاح"]);
    } else {
        error_log("ERROR: Failed to move uploaded file");
        echo json_encode(["success" => false, "message" => "فشل في رفع الملف"]);
    }
} else {
    error_log("ERROR: No file or fileName received");
    echo json_encode(["success" => false, "message" => "لم يتم استلام الملف"]);
}
?>