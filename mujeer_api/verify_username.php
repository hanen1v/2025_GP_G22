<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

include 'config.php';

$data = json_decode(file_get_contents("php://input"));

if($data === null || !isset($data->username)) {
    echo json_encode(["success" => false, "message" => "بيانات غير مكتملة"]);
    exit;
}

$username = $data->username;

// البحث في جدول client أولاً
$sql = "SELECT ClientID as id, FullName, Username, PhoneNumber, 'client' as userType FROM client WHERE Username = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("s", $username);
$stmt->execute();
$result = $stmt->get_result();

if ($result && $result->num_rows > 0) {
    $user = $result->fetch_assoc();
    echo json_encode([
        "success" => true, 
        "user" => [
            "id" => $user['id'],
            "userType" => $user['userType'],
            "fullName" => $user['FullName'],
            "phoneNumber" => $user['PhoneNumber'],
            "username" => $user['Username'],
            "isAdmin" => false,
            "isLawyer" => false
        ]
    ]);
    exit;
}

// البحث في جدول lawyer
$sql = "SELECT LawyerID as id, FullName, Username, PhoneNumber, 'lawyer' as userType FROM lawyer WHERE Username = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("s", $username);
$stmt->execute();
$result = $stmt->get_result();

if ($result && $result->num_rows > 0) {
    $user = $result->fetch_assoc();
    echo json_encode([
        "success" => true, 
        "user" => [
            "id" => $user['id'],
            "userType" => $user['userType'],
            "fullName" => $user['FullName'],
            "phoneNumber" => $user['PhoneNumber'],
            "username" => $user['Username'],
            "isAdmin" => false,
            "isLawyer" => true
        ]
    ]);
    exit;
}

// البحث في جدول admin
$sql = "SELECT AdminID as id, Username, 'admin' as userType, PhoneNumber, Username as FullName FROM admin WHERE Username = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("s", $username);
$stmt->execute();
$result = $stmt->get_result();

if ($result && $result->num_rows > 0) {
    $user = $result->fetch_assoc();
    echo json_encode([
        "success" => true, 
        "user" => [
            "id" => $user['id'],
            "userType" => $user['userType'],
            "fullName" => $user['FullName'],
            "phoneNumber" => $user['PhoneNumber'],
            "username" => $user['Username'],
            "isAdmin" => true,
            "isLawyer" => false
        ]
    ]);
    exit;
}

echo json_encode(["success" => false, "message" => "لم يتم العثور على اسم المستخدم"]);

$conn->close();
?>