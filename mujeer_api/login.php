<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

// تفعيل السجلات
error_reporting(E_ALL);
ini_set('display_errors', 1);

include 'config.php';

// سجل البيانات المستلمة
$raw_input = file_get_contents("php://input");
error_log("=== LOGIN ATTEMPT ===");
error_log("Raw input: " . $raw_input);

$data = json_decode($raw_input);

if($data === null || !isset($data->username) || !isset($data->password)) {
    error_log("ERROR: Missing data or JSON decode failed");
    echo json_encode(["success" => false, "message" => "بيانات غير مكتملة"]);
    exit;
}

$username = $data->username;
$password = $data->password;

error_log("Username: " . $username);
error_log("Password: " . $password);

// تحقق من الاتصال بالداتابيز
if ($conn->connect_error) {
    error_log("DB Connection failed: " . $conn->connect_error);
    echo json_encode(["success" => false, "message" => "فشل الاتصال بقاعدة البيانات"]);
    exit;
}

error_log("DB Connection: OK");

// البحث في جدول client أولاً
$sql = "SELECT ClientID as UserID, FullName, Username, PhoneNumber, Points, 'client' as UserType, Password 
        FROM client WHERE Username = '$username'";
$result = $conn->query($sql);

error_log("=== CHECKING CLIENT TABLE ===");
if ($result && $result->num_rows > 0) {
    $user = $result->fetch_assoc();
    
    error_log("✅ المستخدم موجود في client: " . $user['Username']);
    error_log("🔐 كلمة المرور المخزنة: " . $user['Password']);
    error_log("⌨️ كلمة المرور المدخلة: " . $password);
    
    // تحقق مما إذا كانت كلمة المرور مشفرة
    $is_hashed = password_verify($password, $user['Password']);
    error_log("نتيجة التحقق: " . ($is_hashed ? "✅ ناجح" : "❌ فاشل"));
    
    if ($is_hashed) {
        error_log("🎉 تسجيل الدخول ناجح للعميل");
        unset($user['Password']);
        echo json_encode(["success" => true, "user" => $user]);
        exit;
    } else {
        error_log("❌ فشل التحقق للعميل - كلمة المرور لا تطابق");
    }
} else {
    error_log("❌ المستخدم غير موجود في جدول client");
}

// البحث في جدول lawyer
error_log("=== CHECKING LAWYER TABLE ===");
$sql = "SELECT LawyerID as UserID, FullName, Username, PhoneNumber, 'lawyer' as UserType, Password 
        FROM lawyer WHERE Username = '$username'";
$result = $conn->query($sql);

if ($result && $result->num_rows > 0) {
    $user = $result->fetch_assoc();
    
    error_log("✅ المستخدم موجود في lawyer: " . $user['Username']);
    error_log("🔐 كلمة المرور المخزنة: " . $user['Password']);
    error_log("⌨️ كلمة المرور المدخلة: " . $password);
    
    $is_hashed = password_verify($password, $user['Password']);
    error_log("نتيجة التحقق: " . ($is_hashed ? "✅ ناجح" : "❌ فاشل"));
    
    if ($is_hashed) {
        error_log("🎉 تسجيل الدخول ناجح للمحامي");
        unset($user['Password']);
        echo json_encode(["success" => true, "user" => $user]);
        exit;
    } else {
        error_log("❌ فشل التحقق للمحامي - كلمة المرور لا تطابق");
    }
} else {
    error_log("❌ المستخدم غير موجود في جدول lawyer");
}

// البحث في جدول admin
error_log("=== CHECKING ADMIN TABLE ===");
$sql = "SELECT AdminID as UserID, Username, 'admin' as UserType, Password, 
               Username as FullName,
               '' as PhoneNumber
        FROM admin WHERE Username = '$username'";
$result = $conn->query($sql);

if ($result && $result->num_rows > 0) {
    $user = $result->fetch_assoc();
    
    error_log("✅ المستخدم موجود في admin: " . $user['Username']);
    error_log("🔐 كلمة المرور المخزنة: " . $user['Password']);
    error_log("⌨️ كلمة المرور المدخلة: " . $password);
    
    $is_hashed = password_verify($password, $user['Password']);
    error_log("نتيجة التحقق: " . ($is_hashed ? "✅ ناجح" : "❌ فاشل"));
    
    if ($is_hashed) {
        error_log("🎉 تسجيل الدخول ناجح للمشرف");
        unset($user['Password']);
        echo json_encode(["success" => true, "user" => $user]);
        exit;
    } else {
        error_log("❌ فشل التحقق للمشرف - كلمة المرور لا تطابق");
    }
} else {
    error_log("❌ المستخدم غير موجود في جدول admin");
}

error_log("=== LOGIN FAILED ===");
error_log("لم يتم العثور على المستخدم أو كلمة المرور غير صحيحة في جميع الجداول");
echo json_encode(["success" => false, "message" => "اسم المستخدم أو كلمة المرور غير صحيحة"]);

$conn->close();
?>