<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

error_reporting(E_ALL);
ini_set('display_errors', 1);

include 'config.php';

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

if ($conn->connect_error) {
    error_log("DB Connection failed: " . $conn->connect_error);
    echo json_encode(["success" => false, "message" => "فشل الاتصال بقاعدة البيانات"]);
    exit;
}

error_log("DB Connection: OK");

$sql = "SELECT ClientID as UserID, FullName, Username, PhoneNumber, Points, 'client' as UserType, Password 
        FROM client WHERE Username = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("s", $username);
$stmt->execute();
$result = $stmt->get_result();

error_log("=== CHECKING CLIENT TABLE ===");
if ($result && $result->num_rows > 0) {
    $user = $result->fetch_assoc();
    
    error_log(" المستخدم موجود في client: " . $user['Username']);
    error_log(" كلمة المرور المخزنة: " . $user['Password']);
    error_log(" كلمة المرور المدخلة: " . $password);
    
    $is_hashed = password_verify($password, $user['Password']);
    error_log("نتيجة التحقق: " . ($is_hashed ? " ناجح" : " فاشل"));
    
    if ($is_hashed) {
        error_log(" تسجيل الدخول ناجح للعميل");
        
        echo json_encode([
            "success" => true, 
            "message" => "تم تسجيل الدخول بنجاح",
            "user" => [
                "id" => $user['UserID'],
                "userType" => $user['UserType'],
                "fullName" => $user['FullName'],
                "phoneNumber" => $user['PhoneNumber'],
                "username" => $user['Username'],
                "points" => $user['Points'],
                "isAdmin" => false,
                "isLawyer" => false
            ]
        ]);
        exit;
    } else {
        error_log(" فشل التحقق للعميل - كلمة المرور لا تطابق");
    }
} else {
    error_log(" المستخدم غير موجود في جدول client");
}

error_log("=== CHECKING LAWYER TABLE ===");

$sql = "SELECT 
    LawyerID AS UserID,
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
    LicenseNumber,
    'lawyer' AS UserType,
    Password
FROM lawyer 
WHERE Username = ?";

$stmt = $conn->prepare($sql);
$stmt->bind_param("s", $username);
$stmt->execute();
$result = $stmt->get_result();

if ($result && $result->num_rows > 0) {
    $user = $result->fetch_assoc();
    
    error_log(" المستخدم موجود في lawyer: " . $user['Username']);
    error_log(" كلمة المرور المخزنة: " . $user['Password']);
    error_log(" كلمة المرور المدخلة: " . $password);
    
    $is_hashed = password_verify($password, $user['Password']);
    error_log("نتيجة التحقق: " . ($is_hashed ? " ناجح" : " فاشل"));
    
    if ($is_hashed) {
        error_log(" تسجيل الدخول ناجح للمحامي");
        
        echo json_encode([
            "success" => true, 
            "success" => true,
            "message" => "تم تسجيل الدخول بنجاح",
            "user" => [
                "id" => $user['UserID'],
                "userType" => $user['UserType'],
                "fullName" => $user['FullName'],
                "phoneNumber" => $user['PhoneNumber'],
                "username" => $user['Username'],
                "points" => $user['Points'],
                "status" => $user['Status'],
                "yearsOfExp" => $user['YearsOfExp'],
                "mainSpecialization" => $user['MainSpecialization'],
                "fSubSpecialization" => $user['FSubSpecialization'],
                "sSubSpecialization" => $user['SSubSpecialization'],
                "educationQualification" => $user['EducationQualification'],
                "academicMajor" => $user['AcademicMajor'],
                "LawyerPhoto" => $user['LawyerPhoto'],
                "licenseNumber" => $user['LicenseNumber'],
                "isAdmin" => false,
                "isLawyer" => true
            ]
         ], JSON_UNESCAPED_UNICODE);
        exit;
    } else {
        error_log(" فشل التحقق للمحامي - كلمة المرور لا تطابق");
    }
} else {
    error_log(" المستخدم غير موجود في جدول lawyer أو الحساب غير مفعل");
}

error_log("=== CHECKING ADMIN TABLE ===");
$sql = "SELECT AdminID as UserID, Username, 'admin' as UserType, Password, 
               Username as FullName,
               PhoneNumber  
        FROM admin WHERE Username = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("s", $username);
$stmt->execute();
$result = $stmt->get_result();

if ($result && $result->num_rows > 0) {
    $user = $result->fetch_assoc();
    
    error_log(" المستخدم موجود في admin: " . $user['Username']);
    error_log(" كلمة المرور المخزنة: " . $user['Password']);
    error_log(" كلمة المرور المدخلة: " . $password);
    
    $is_hashed = password_verify($password, $user['Password']);
    error_log("نتيجة التحقق: " . ($is_hashed ? " ناجح" : " فاشل"));
    
    if ($is_hashed) {
        error_log(" تسجيل الدخول ناجح للمشرف");
        
        echo json_encode([
            "success" => true, 
            "message" => "تم تسجيل الدخول بنجاح", 
            "user" => [
                "id" => $user['UserID'],
                "userType" => $user['UserType'],
                "fullName" => $user['FullName'],
                "phoneNumber" => $user['PhoneNumber'],
                "username" => $user['Username'],
                "isAdmin" => true,
                "isLawyer" => false
            ]
        ]);
        exit;
    } else {
        error_log(" فشل التحقق للمشرف - كلمة المرور لا تطابق");
    }
} else {
    error_log(" المستخدم غير موجود في جدول admin");
}

error_log("=== LOGIN FAILED ===");
error_log("لم يتم العثور على المستخدم أو كلمة المرور غير صحيحة في جميع الجداول");
echo json_encode(["success" => false, "message" => "اسم المستخدم أو كلمة المرور غير صحيحة"]);

$conn->close();
?>
