<?php

error_reporting(E_ALL);
ini_set('display_errors', 1);


header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");


$servername = "localhost";
$username = "root"; 
$password = "root";     
$dbname = "mujeer"; 

$conn = new mysqli($servername, $username, $password, $dbname, 8889);
$conn->set_charset("utf8mb4");


if ($conn->connect_error) {
    die(json_encode(["error" => "فشل الاتصال بقاعدة البيانات: " . $conn->connect_error], JSON_UNESCAPED_UNICODE));
}

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
            Price 
        FROM lawyer
        WHERE Status = 'Approved'";

$result = $conn->query($sql);

$lawyers = [];

if ($result && $result->num_rows > 0) {
    while ($row = $result->fetch_assoc()) {
        
        $id = $row['LawyerID'];
        $rateQuery = $conn->query("SELECT AVG(Rate) AS avgRate FROM feedback WHERE LawyerID = $id");
        $avgRate = 0;
        if ($rateQuery && $rateQuery->num_rows > 0) {
            $rateRow = $rateQuery->fetch_assoc();
            $avgRate = round(floatval($rateRow['avgRate'] ?? 0), 1);
        }

    
        $lawyers[] = [
            "id" => $row['LawyerID'],
            "name" => $row['FullName'],
            "rating" => $avgRate,
            "experience" => $row['YearsOfExp'] . " سنوات",
            "speciality" => $row['MainSpecialization'],
            "subSpeciality" => $row['FSubSpecialization'],
            "ssubSpeciality" => $row['SSubSpecialization'],
            "academic" => $row['AcademicMajor'],
            "degree" => $row['EducationQualification'],
            "image" => $row['LawyerPhoto'], // مسار الصورة كما في قاعدة البيانات
            "price" => floatval($row['Price'])
        ];
    }
}


echo json_encode($lawyers, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);

$conn->close();
?>
