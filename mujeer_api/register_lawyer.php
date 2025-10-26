<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

// تفعيل السجلات
error_reporting(E_ALL);
ini_set('display_errors', 0); // ✅ لا تطبعي الأخطاء للمستخدم
ini_set('log_errors', 1);     // سجليها في اللوج فقط


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
<<<<<<< HEAD
    $lawyerID = $conn->insert_id; // جلب الـ ID الجديد
    
=======
    $lawyerId = (int)$conn->insert_id; // ← ثبّتي الاسم هكذا

>>>>>>> 81d635de62acee9cfb11a5abf785461b7d1ab218
    // إنشاء طلب في جدول request
    $request_sql = "INSERT INTO request (AdminID, LawyerID, LawyerLicense, LawyerName, LicenseNumber, Status, RequestDate) 
                    VALUES (1, $lawyerId, '$licenseFileName', '$fullName', '$licenseNumber', 'Pending', NOW())";
    if($conn->query($request_sql)) {
        error_log("SUCCESS: Request created for lawyer ID: " . $lawyerId);
        $requestId = (int)$conn->insert_id; // ← رقم الطلب في متغير منفصل
    } else {
        error_log("ERROR: Failed to create request - " . $conn->error);
    }

    // اقرأ صف المحامي بالـID الصحيح
    $sel = "
      SELECT 
        LawyerID AS UserID,
        FullName,
        Username,
        PhoneNumber,
        TRIM(Status) AS Status,
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
        $lawyerRow = [
          "UserID" => $lawyerId,     // ← استخدمي نفس الـID
          "FullName" => $fullName,
          "Username" => $username,
          "PhoneNumber" => $phoneNumber,
           "Status" => "Pending",
          "Points" => 0,
          "LawyerPhoto" => $photoFileName,
          "UserType" => "lawyer",
          "RegistrationDate" => date('c')
        ];
    }
    
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

    // ✅ تطبيع قبل الإرجاع
    if (isset($lawyerRow['LawyerID']) && !isset($lawyerRow['UserID'])) {
       $lawyerRow['UserID'] = (int)$lawyerRow['LawyerID'];
       unset($lawyerRow['LawyerID']);
      }
      $rawStatus = strtolower(trim($lawyerRow['Status'] ?? ''));
        if ($rawStatus === 'approved')      $lawyerRow['Status'] = 'Approved';
        elseif ($rawStatus === 'rejected')  $lawyerRow['Status'] = 'Rejected';
        else                                $lawyerRow['Status'] = 'Pending';  // default
        $lawyerRow['UserType'] = 'lawyer';

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
