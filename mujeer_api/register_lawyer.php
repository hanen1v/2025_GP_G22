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
error_log("=== LAWYER REGISTRATION ATTEMPT ===");
error_log("Raw input: " . $raw_input);

$data = json_decode($raw_input);

if($data === null) {
    error_log("ERROR: JSON decode failed");
    echo json_encode(["success" => false, "message" => "بيانات غير صالحة"]);
    exit;
}

// التحقق من البيانات المطلوبة
$required_fields = ['username', 'fullName', 'password', 'phoneNumber', 'licenseNumber', 
                   'yearsOfExp', 'gender', 'mainSpecialization', 'educationQualification', 'academicMajor'];

foreach($required_fields as $field) {
    if(!isset($data->$field) || empty($data->$field)) {
        error_log("ERROR: Missing field: " . $field);
        echo json_encode(["success" => false, "message" => "حقل {$field} مطلوب"]);
        exit;
    }
}

// استخراج البيانات
$username = $conn->real_escape_string($data->username);
$fullName = $conn->real_escape_string($data->fullName);
$password = $data->password;
$phoneNumber = $conn->real_escape_string($data->phoneNumber);
$licenseNumber = $conn->real_escape_string($data->licenseNumber);
$yearsOfExp = intval($data->yearsOfExp);
$gender = $conn->real_escape_string($data->gender);
$mainSpecialization = $conn->real_escape_string($data->mainSpecialization);
$educationQualification = $conn->real_escape_string($data->educationQualification);
$academicMajor = $conn->real_escape_string($data->academicMajor);

// الحقول الاختيارية
$fSubSpecialization = isset($data->fSubSpecialization) ? $conn->real_escape_string($data->fSubSpecialization) : '';
$sSubSpecialization = isset($data->sSubSpecialization) ? $conn->real_escape_string($data->sSubSpecialization) : '';

// تحويل الجنس من العربية إلى الإنجليزية
$gender_english = ($gender == 'ذكر') ? 'Male' : 'Female';

// إنشاء أسماء فريدة للملفات
$licenseFileName = 'license_' . $username . '_' . time() . '.pdf';
$photoFileName = 'photo_' . $username . '_' . time() . '.jpg';

error_log("Processing registration for: " . $username);

// التحقق من عدم تكرار اسم المستخدم أو رقم الجوال
$check_sql = "SELECT Username, PhoneNumber FROM lawyer 
              WHERE Username = '$username' OR PhoneNumber = '$phoneNumber'";
$check_result = $conn->query($check_sql);

if($check_result && $check_result->num_rows > 0) {
    while($existing = $check_result->fetch_assoc()) {
        if($existing['Username'] == $username) {
            error_log("ERROR: Username already exists");
            echo json_encode(["success" => false, "message" => "اسم المستخدم موجود مسبقاً"]);
            exit;
        }
        if($existing['PhoneNumber'] == $phoneNumber) {
            error_log("ERROR: Phone number already exists");
            echo json_encode(["success" => false, "message" => "رقم الجوال موجود مسبقاً"]);
            exit;
        }
    }
}

// تشفير كلمة المرور
$hashed_password = password_hash($password, PASSWORD_DEFAULT);

// إدخال البيانات في جدول lawyer
$sql = "INSERT INTO lawyer (Username, FullName, PhoneNumber, Password, LicenseNumber, YearsOfExp, Gender, 
                           MainSpecialization, FSubSpecialization, SSubSpecialization, 
                           EducationQualification, AcademicMajor, LicenseFile, LawyerPhoto, Status) 
        VALUES ('$username', '$fullName', '$phoneNumber', '$hashed_password', '$licenseNumber', 
                $yearsOfExp, '$gender_english', '$mainSpecialization', '$fSubSpecialization', 
                '$sSubSpecialization', '$educationQualification', '$academicMajor', 
                '$licenseFileName', '$photoFileName', 'Pending')";

error_log("Executing SQL: " . $sql);

if($conn->query($sql) === TRUE) {
     $lawyerID = $conn->insert_id; // جلب الـ ID الجديد
    
    // إنشاء طلب في جدول request
    $request_sql = "INSERT INTO request (AdminID, LawyerID, LawyerLicense, LawyerName, LicenseNumber, Status, RequestDate) 
                    VALUES (1, '$lawyerID', '$licenseFileName', '$fullName', '$licenseNumber', 'Pending', NOW())";
    
    if($conn->query($request_sql)) {
        error_log("SUCCESS: Request created for lawyer ID: " . $lawyerID);
    } else {
        error_log("ERROR: Failed to create request - " . $conn->error);
    }
    error_log("SUCCESS: Lawyer registered successfully");

    // احصلي على الـ ID الجديد
    $lawyerId = $conn->insert_id;

    // اقري صف المحامي (يتضمن Points)
    $sel = "
      SELECT 
        LawyerID,
        FullName,
        Username,
        PhoneNumber,
        COALESCE(Points, 0) AS Points,
        LawyerPhoto,
        'lawyer' AS UserType,
        NOW() AS RegistrationDate
      FROM lawyer
      WHERE LawyerID = $lawyerId
      LIMIT 1
    ";
    $res = $conn->query($sel);

    if ($res && $res->num_rows === 1) {
        $lawyerRow = $res->fetch_assoc();
    } else {
        // احتياط
        $lawyerRow = [
          "LawyerID" => $lawyerId,
          "FullName" => $fullName,
          "Username" => $username,
          "PhoneNumber" => $phoneNumber,
          "Points" => 0,
          "LawyerPhoto" => $photoFileName,
          "UserType" => "lawyer",
          "RegistrationDate" => date('c')
        ];
    }

    echo json_encode([
        "success" => true, 
        "message" => "تم تسجيل المحامي بنجاح! سيتم مراجعة طلبك من قبل الإدارة.",
        "licenseFileName" => $licenseFileName,
        "photoFileName"   => $photoFileName,
        "lawyer" => $lawyerRow
    ]);
}  else {
    error_log("ERROR: Database insert failed - " . $conn->error);
    echo json_encode(["success" => false, "message" => "فشل في التسجيل: " . $conn->error]);
}

$conn->close();
?>