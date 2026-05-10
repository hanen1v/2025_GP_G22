<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

error_reporting(E_ALL);
ini_set('display_errors', 1);

include 'config.php';

$data = json_decode(file_get_contents("php://input"), true);

if ($data === null) {
    echo json_encode(["available" => false, "message" => "بيانات غير صالحة"]);
    exit;
}

$userType = $data['userType'] ?? '';
$table = ($userType == 'lawyer') ? 'lawyer' : 'client';

// التحقق من اسم المستخدم
if (isset($data['username'])) {
    $username = $conn->real_escape_string($data['username']);
    $sql = "SELECT COUNT(*) as count FROM $table WHERE Username = '$username'";
    $result = $conn->query($sql);
    
    if ($result) {
        $row = $result->fetch_assoc();
        $isAvailable = ($row['count'] == 0);
        
        echo json_encode([
            'available' => $isAvailable,
            'message' => $isAvailable 
                ? '✔ اسم المستخدم متاح' 
                : '✘ اسم المستخدم محجوز مسبقاً'
        ]);
    } else {
        echo json_encode(['available' => false, 'message' => 'خطأ في التحقق']);
    }
}

// التحقق من رقم الجوال
elseif (isset($data['phoneNumber'])) {
    $phoneNumber = $conn->real_escape_string($data['phoneNumber']);
    $sql = "SELECT COUNT(*) as count FROM $table WHERE PhoneNumber = '$phoneNumber'";
    $result = $conn->query($sql);
    
    if ($result) {
        $row = $result->fetch_assoc();
        $isAvailable = ($row['count'] == 0);
        
        echo json_encode([
            'available' => $isAvailable,
            'message' => $isAvailable 
                ? '✔ رقم الجوال متاح' 
                : '✘ رقم الجوال مسجل مسبقاً'
        ]);
    } else {
        echo json_encode(['available' => false, 'message' => 'خطأ في التحقق']);
    }
}

// التحقق من رقم الرخصة (للمحامي فقط)
elseif (isset($data['licenseNumber']) && $userType == 'lawyer') {
    $licenseNumber = $conn->real_escape_string($data['licenseNumber']);
    $sql = "SELECT COUNT(*) as count FROM lawyer WHERE LicenseNumber = '$licenseNumber'";
    $result = $conn->query($sql);
    
    if ($result) {
        $row = $result->fetch_assoc();
        $isAvailable = ($row['count'] == 0);
        
        echo json_encode([
            'available' => $isAvailable,
            'message' => $isAvailable 
                ? '✔ رقم الرخصة متاح' 
                : '✘ رقم الرخصة مسجل مسبقاً'
        ]);
    } else {
        echo json_encode(['available' => false, 'message' => 'خطأ في التحقق']);
    }
}

else {
    echo json_encode(["available" => false, "message" => "بيانات غير كافية"]);
}

$conn->close();
?>