<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);
require_once __DIR__ . '/config.php';
error_reporting(E_ALL);
ini_set('display_errors', 1);

header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

if (!isset($_GET['id'])) {
    echo json_encode(['success' => false, 'message' => 'لم يتم إرسال رقم المحامي']);
    exit;
}

$id = intval($_GET['id']);

$sql = "SELECT 
            LawyerID, 
            FullName, 
            YearsOfExp, 
            MainSpecialization, 
            FSubSpecialization, 
            SSubSpecialization, 
            EducationQualification, 
            AcademicMajor, 
            LawyerPhoto, 
            Price,
			LicenseNumber
        FROM lawyer
        WHERE LawyerID = $id AND Status = 'Approved'";

$result = $conn->query($sql);

if ($result && $result->num_rows > 0) {
    $row = $result->fetch_assoc();

    // حساب التقييم من جدول feedback
    $rateQuery = $conn->query("SELECT AVG(Rate) AS avgRate FROM feedback WHERE LawyerID = $id");
    $avgRate = 0;
    if ($rateQuery && $rateQuery->num_rows > 0) {
        $rateRow = $rateQuery->fetch_assoc();
        $avgRate = round(floatval($rateRow['avgRate'] ?? 0), 1);
    }

    $imagePath = "";
    if (!empty($row['LawyerPhoto'])) {
        $imagePath = "http://" . $_SERVER['HTTP_HOST'] . "/mujeer_api/uploads/" . $row['LawyerPhoto'];
    }

    $lawyer = [
        "id" => $row['LawyerID'],
        "name" => $row['FullName'],
        "rating" => $avgRate,
        "experience" => $row['YearsOfExp'] . " سنوات",
        "speciality" => $row['MainSpecialization'],
        "subSpeciality" => $row['FSubSpecialization'],
        "ssubSpeciality" => $row['SSubSpecialization'],
        "academic" => $row['AcademicMajor'],
        "degree" => $row['EducationQualification'],
        "image" => $imagePath,
        "price" => floatval($row['Price']),
		"license" => $row['LicenseNumber'],

    ];

    echo json_encode($lawyer, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
} else {
    echo json_encode(['success' => false, 'message' => 'لم يتم العثور على المحامي']);
}

$conn->close();
?>
