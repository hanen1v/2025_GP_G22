<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

error_reporting(E_ALL);
ini_set('display_errors', 1);

include 'config.php';

// قراءة البيانات المرسلة من Flutter
$raw_input = file_get_contents("php://input");
$data = json_decode($raw_input, true);

if ($data === null) {
    echo json_encode(["success" => false, "message" => "البيانات غير صالحة"]);
    exit;
}

// استخراج البيانات
$fullName = $data["fullName"] ?? "";
$username = $data["username"] ?? "";
$password = $data["password"] ?? "";
$phoneNumber = $data["phoneNumber"] ?? "";
$licenseNumber = $data["licenseNumber"] ?? "";
$yearsOfExp = $data["yearsOfExp"] ?? "";
$gender = $data["gender"] ?? "";
$mainSpecialization = $data["mainSpecialization"] ?? "";
$educationQualification = $data["educationQualification"] ?? "";
$academicMajor = $data["academicMajor"] ?? "";
$fSubSpecialization = $data["fSubSpecialization"] ?? "";
$sSubSpecialization = $data["sSubSpecialization"] ?? "";

// ⭐ تحويل الجنس من عربي لإنجليزي
$gender_english = ($gender == 'ذكر') ? 'Male' : 'Female';

// ⭐ تشفير كلمة المرور
$hashed_password = password_hash($password, PASSWORD_DEFAULT);

// ⭐ إنشاء أسماء ملفات افتراضية (سيتم تحديثها لاحقاً عند رفع الملفات)
$license_file_name = "license_" . $username . "_" . time() . ".pdf";
$photo_file_name = "photo_" . $username . "_" . time() . ".jpg";

// التحقق من الحقول المطلوبة
$required_fields = ['fullName', 'username', 'password', 'phoneNumber', 'licenseNumber', 'yearsOfExp', 'gender', 'mainSpecialization', 'educationQualification', 'academicMajor'];
foreach($required_fields as $field) {
    if(empty($data[$field])) {
        echo json_encode(["success" => false, "message" => "حقل {$field} مطلوب"]);
        exit;
    }
}

// تأكد من نجاح الاتصال بقاعدة البيانات
if ($conn->connect_error) {
    echo json_encode(["success" => false, "message" => "فشل الاتصال بقاعدة البيانات: " . $conn->connect_error]);
    exit;
}

// ⭐⭐ استعلام الإدخال مع جميع الأعمدة المطلوبة
$sql = "INSERT INTO lawyer (
    FullName, 
    Username, 
    Password, 
    PhoneNumber, 
    LicenseNumber, 
    YearsOfExp, 
    Gender, 
    MainSpecialization, 
    FSubSpecialization, 
    SSubSpecialization, 
    LicenseFile, 
    EducationQualification, 
    AcademicMajor, 
    LawyerPhoto, 
    Status, 
    Points
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'Pending', 0)";

$stmt = $conn->prepare($sql);
if (!$stmt) {
    echo json_encode(["success" => false, "message" => "خطأ في إعداد الاستعلام: " . $conn->error]);
    exit;
}

// ⭐ ربط المعاملات مع أنواع البيانات الصحيحة
$stmt->bind_param("sssssissssssss", 
    $fullName, 
    $username, 
    $hashed_password,  // ⭐ استخدام كلمة المرور المشفرة
    $phoneNumber, 
    $licenseNumber, 
    $yearsOfExp, 
    $gender_english,  // ⭐ أرسل الجنس بالإنجليزية
    $mainSpecialization, 
    $fSubSpecialization, 
    $sSubSpecialization, 
    $license_file_name,  // ⭐ اسم ملف الرخصة
    $educationQualification, 
    $academicMajor, 
    $photo_file_name   // ⭐ اسم ملف الصورة
);


//get id to send notifications
    $q = $conn->prepare("SELECT player_id FROM admin_devices");
    $q->execute();
    $res = $q->get_result();
    $players = [];
    while ($row = $res->fetch_assoc()) {
        if (!empty($row['player_id'])) {
            $players[] = $row['player_id'];         }
    }
    $q->close();

    $pushResult = null;
    if (!empty($players)) {
        $title = 'طلب جديد';
                $body  = "محامي جديد سجل الدخول";
        $data  = [];

        $pushResult = send_push($players, $title, $body, $data); 
    }

    
// ⭐⭐ التصحيح: نفذ الإدخال أولاً ثم أرسل الإشعارات
if ($stmt->execute()) {
    $lawyerId = $conn->insert_id;
    
    // ⭐ إضافة طلب للمشرفين
    $request_sql = "INSERT INTO request (AdminID, LawyerID, LawyerLicense, LawyerName, LicenseNumber, Status)
                    VALUES (1, ?, ?, ?, ?, 'Pending')";
    $request_stmt = $conn->prepare($request_sql);
    if ($request_stmt) {
        $request_stmt->bind_param("isss", $lawyerId, $license_file_name, $fullName, $licenseNumber);
        $request_stmt->execute();
        $request_stmt->close();
    }

    // ⭐ إرسال إشعارات للمشرفين (بعد نجاح الإدخال)
    $q = $conn->prepare("SELECT player_id FROM admin_devices");
    $q->execute();
    $res = $q->get_result();
    $players = [];
    while ($row = $res->fetch_assoc()) {
        if (!empty($row['player_id'])) {
            $players[] = $row['player_id'];
        }
    }
    $q->close();

    $pushResult = null;
    if (!empty($players)) {
        $title = 'طلب جديد';
        $body  = "محامي جديد سجل الدخول";
        $data  = [];
        $pushResult = send_push($players, $title, $body, $data); 
    }

    // ⭐ جلب بيانات المحامي المسجل
    $user = null;
    $uRes = $conn->query("
        SELECT
            LawyerID          AS UserID,
            FullName,
            Username,
            PhoneNumber,
            Points,
            YearsOfExp,
            MainSpecialization,
            FSubSpecialization,
            SSubSpecialization,
            EducationQualification,
            AcademicMajor,
            Status,
            LawyerPhoto
            LicenseNumber
        FROM lawyer
        WHERE LawyerID = $lawyerId
        LIMIT 1
    ");

    if ($uRes && $uRes->num_rows === 1) {
        $user = $uRes->fetch_assoc();
    }

    if ($user) {
        $user['LawyerID'] = $lawyerId;
        $user['UserType'] = 'lawyer';
    }

    echo json_encode([
        "success"        => true,
        "message"        => "تم تسجيل المحامي بنجاح! سيتم مراجعة طلبك",
        "userId"         => $lawyerId,
        "licenseFileName"=> $license_file_name,
        "photoFileName"  => $photo_file_name,
        "user"           => $user
    ], JSON_UNESCAPED_UNICODE);

} else {
    // التحقق من وجود مستخدم مكرر
    if ($conn->errno == 1062) {
        echo json_encode(["success" => false, "message" => "اسم المستخدم أو رقم الجوال أو رقم الرخصة مسجل مسبقاً"]);
    } else {
        echo json_encode(["success" => false, "message" => "حدث خطأ أثناء التسجيل: " . $stmt->error]);
    }
}

$stmt->close();
$conn->close();
?>