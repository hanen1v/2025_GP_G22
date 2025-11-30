<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

error_reporting(E_ALL);
ini_set('display_errors', 1);

include 'config.php';

$raw_input = file_get_contents("php://input");
$data = json_decode($raw_input, true);

if ($data === null) {
    echo json_encode(["success" => false, "message" => "البيانات غير صالحة"]);
    exit;
}

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

$gender_english = ($gender == 'ذكر') ? 'Male' : 'Female';

$hashed_password = password_hash($password, PASSWORD_DEFAULT);

$license_file_name = "license_" . $username . "_" . time() . ".pdf";
$photo_file_name = "photo_" . $username . "_" . time() . ".jpg";

$required_fields = ['fullName', 'username', 'password', 'phoneNumber', 'licenseNumber', 'yearsOfExp', 'gender', 'mainSpecialization', 'educationQualification', 'academicMajor'];
foreach($required_fields as $field) {
    if(empty($data[$field])) {
        echo json_encode(["success" => false, "message" => "حقل {$field} مطلوب"]);
        exit;
    }
}

if ($conn->connect_error) {
    echo json_encode(["success" => false, "message" => "فشل الاتصال بقاعدة البيانات: " . $conn->connect_error]);
    exit;
}

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

$stmt->bind_param("sssssissssssss", 
    $fullName, 
    $username, 
    $hashed_password,  
    $phoneNumber, 
    $licenseNumber, 
    $yearsOfExp, 
    $gender_english,  
    $mainSpecialization, 
    $fSubSpecialization, 
    $sSubSpecialization, 
    $license_file_name,  
    $educationQualification, 
    $academicMajor, 
    $photo_file_name
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

    
if ($stmt->execute()) {
    $lawyerId = $conn->insert_id;
    
    $request_sql = "INSERT INTO request (AdminID, LawyerID, LawyerLicense, LawyerName, LicenseNumber, Status)
                    VALUES (1, ?, ?, ?, ?, 'Pending')";
    $request_stmt = $conn->prepare($request_sql);
    if ($request_stmt) {
        $request_stmt->bind_param("isss", $lawyerId, $license_file_name, $fullName, $licenseNumber);
        $request_stmt->execute();
        $request_stmt->close();
    }

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
    
    if ($conn->errno == 1062) {
        echo json_encode(["success" => false, "message" => "اسم المستخدم أو رقم الجوال أو رقم الرخصة مسجل مسبقاً"]);
    } else {
        echo json_encode(["success" => false, "message" => "حدث خطأ أثناء التسجيل: " . $stmt->error]);
    }
}

$stmt->close();
$conn->close();
?>
