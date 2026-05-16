<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

error_reporting(E_ALL);
ini_set('display_errors', 0);

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
$gender = $data["gender"] ?? "";
$mainSpecialization = $data["mainSpecialization"] ?? "";
$educationQualification = $data["educationQualification"] ?? "";
$academicMajor = $data["academicMajor"] ?? "";
$fSubSpecialization = $data["fSubSpecialization"] ?? "";
$sSubSpecialization = $data["sSubSpecialization"] ?? "";

// ✅ احسب yearsOfExp من startMonth و startYear
$startMonth = isset($data["startMonth"]) ? (int)$data["startMonth"] : 0;
$startYear  = isset($data["startYear"])  ? (int)$data["startYear"]  : 0;

$currentYear  = (int) date("Y");
$currentMonth = (int) date("n");
$yearsOfExp = $currentYear - $startYear;
if ($currentMonth < $startMonth) $yearsOfExp--;
if ($yearsOfExp < 0) $yearsOfExp = 0;

$required_fields = ['fullName', 'username', 'password', 'phoneNumber', 
                    'licenseNumber', 'gender', 'mainSpecialization', 
                    'educationQualification', 'academicMajor', 'startMonth', 'startYear'];
foreach($required_fields as $field) {
    if(empty($data[$field])) {
        echo json_encode(["success" => false, "message" => "حقل {$field} مطلوب"]);
        exit;
    }
}

// ⭐ تحويل الجنس وتشفير كلمة المرور
$gender_english = ($gender == 'ذكر') ? 'Male' : 'Female';
$hashed_password = password_hash($password, PASSWORD_DEFAULT);

// ⭐ أسماء الملفات الافتراضية
$license_file_name = "license_" . $username . "_" . time() . ".pdf";
$photo_file_name = "photo_" . $username . "_" . time() . ".jpg";

if ($conn->connect_error) {
    echo json_encode(["success" => false, "message" => "فشل الاتصال بقاعدة البيانات"]);
    exit;
}

// 1️⃣ استعلام إدخال المحامي
// ✅ غيّر الـ SQL
$sql = "INSERT INTO lawyer (
    FullName, Username, Password, PhoneNumber, LicenseNumber, 
    StartMonth, StartYear, YearsOfExp, Gender, MainSpecialization, FSubSpecialization, 
    SSubSpecialization, LicenseFile, EducationQualification, 
    AcademicMajor, LawyerPhoto, Status, Points
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'Pending', 0)";

$stmt = $conn->prepare($sql);
if (!$stmt) {
    echo json_encode(["success" => false, "message" => "خطأ في الاستعلام: " . $conn->error]);
    exit;
}

// ✅ أضف ii لـ StartMonth و StartYear
$stmt->bind_param("sssssiiissssssss", 
    $fullName, $username, $hashed_password, $phoneNumber, $licenseNumber,
    $startMonth, $startYear, $yearsOfExp, $gender_english, $mainSpecialization, 
    $fSubSpecialization, $sSubSpecialization, $license_file_name, 
    $educationQualification, $academicMajor, $photo_file_name
);

if ($stmt->execute()) {
    // echo json_encode(["debug" => "1 - insert success"]);
    // exit;
    $lawyerId = $conn->insert_id;
    
    // 2️⃣ إضافة طلب للمشرفين في جدول request
    $request_sql = "INSERT INTO Request (AdminID, LawyerID, LawyerLicense, LawyerName, LicenseNumber, Status)
                    VALUES (1, ?, ?, ?, ?, 'Pending')";
    $request_stmt = $conn->prepare($request_sql);

if (!$request_stmt) {
    echo json_encode([
        "debug" => "prepare failed",
        "error" => $conn->error
    ]);
    exit;
}

// echo json_encode(["debug" => "prepare success"]);
// exit;

$request_stmt->bind_param("isss", $lawyerId, $license_file_name, $fullName, $licenseNumber);

// echo json_encode(["debug" => "bind success"]);
// exit;

$request_stmt->execute();

echo json_encode([
    "debug" => "execute success"
]);
exit;

    // 3️⃣ جلب الـ Player IDs للمشرفين (مرة واحدة فقط هنا)
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
// echo json_encode([
//     "debug" => "3 - players fetched",
//     "players_count" => count($players)
// ]);
// exit;
    // 4️⃣ إرسال الإشعار (سيتم إرسال إشعار واحد فقط الآن)
    if (!empty($players)) {
        $title = 'طلب تسجيل جديد';
        $body  = "المحامي $fullName سجل في النظام وينتظر الموافقة";
        send_push($players, $title, $body, ['type' => 'new_lawyer', 'id' => $lawyerId]); 
//         echo json_encode(["debug" => "4 - push sent"]);
// exit;
    }

    // 5️⃣ جلب بيانات المحامي للرد على التطبيق (تم إصلاح الفاصلة هنا)
    $user = null;
    $uRes = $conn->query("
        SELECT
            LawyerID AS UserID, FullName, Username, PhoneNumber, Points,
            YearsOfExp, MainSpecialization, FSubSpecialization, SSubSpecialization,
            EducationQualification, AcademicMajor, Status, LawyerPhoto, LicenseNumber
        FROM lawyer
        WHERE LawyerID = $lawyerId
        LIMIT 1
    ");
// echo json_encode([
//     "debug" => "5 - user fetched",
//     "rows" => $uRes ? $uRes->num_rows : "query failed"
// ]);
// exit;
    if ($uRes && $uRes->num_rows > 1) {
        $user = $uRes->fetch_assoc();
        $user['UserType'] = 'lawyer';
    }
// echo json_encode([
//     "debug" => "5 - user fetched",
//     "rows" => $uRes ? $uRes->num_rows : "query failed"
// ]);
// exit;
    echo json_encode([
        "success"         => true,
        "message"         => "تم تسجيل المحامي بنجاح! سيتم مراجعة طلبك",
        "userId"          => $lawyerId,
        "licenseFileName" => $license_file_name,
        "photoFileName"   => $photo_file_name,
        "user"            => $user
    ], JSON_UNESCAPED_UNICODE);

} else {
    if ($conn->errno == 1062) {
        echo json_encode(["success" => false, "message" => "البيانات (اليوزر أو الجوال أو الرخصة) مسجلة مسبقاً"]);
    } else {
        echo json_encode(["success" => false, "message" => "خطأ أثناء التسجيل: " . $stmt->error]);
    }
}

$stmt->close();
$conn->close();
?>
