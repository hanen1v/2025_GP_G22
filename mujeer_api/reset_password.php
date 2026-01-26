<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");
header('Content-Type: application/json; charset=utf-8');
mb_internal_encoding('UTF-8');
include 'config.php';

$data = json_decode(file_get_contents("php://input"));

if($data === null || !isset($data->username) || !isset($data->newPassword)) {
    echo json_encode(["success" => false, "message" => "بيانات غير مكتملة"]);
    exit;
}

$username = trim($data->username);
$newPassword = password_hash(trim($data->newPassword), PASSWORD_DEFAULT);

// دالة عامة للتحديث
function updatePassword($conn, $table, $username, $newPassword) {
    // تحقق أولاً هل المستخدم موجود
    $check = $conn->prepare("SELECT * FROM $table WHERE Username = ?");
    $check->bind_param("s", $username);
    $check->execute();
    $result = $check->get_result();

    if ($result->num_rows > 0) {
        // تم العثور على المستخدم → حدّث كلمة المرور
        $sql = "UPDATE $table SET Password = ? WHERE Username = ?";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("ss", $newPassword, $username);
        $stmt->execute();
        return true;
    }

    return false;
}

// تحديث client
if (updatePassword($conn, "client", $username, $newPassword)) {
    echo json_encode(["success" => true, "message" => "تم تحديث كلمة المرور للعميل"]);
    exit;
}

// تحديث lawyer
if (updatePassword($conn, "lawyer", $username, $newPassword)) {
    echo json_encode(["success" => true, "message" => "تم تحديث كلمة المرور للمحامي"]);
    exit;
}

// تحديث admin
if (updatePassword($conn, "admin", $username, $newPassword)) {
    echo json_encode(["success" => true, "message" => "تم تحديث كلمة المرور للمشرف"]);
    exit;
}

echo json_encode(["success" => false, "message" => "لم يتم العثور على المستخدم"]);
$conn->close();
?>
