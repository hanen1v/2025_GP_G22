<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);
require_once __DIR__ . '/config.php';

header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

if (!isset($_GET['id'])) {
    echo json_encode(["success" => false, "message" => "No lawyer ID provided"]);
    exit;
}

$lawyerId = intval($_GET['id']);

$sql = "SELECT 
            feedback.Rate,
            feedback.Review,
            feedback.DateGiven,
            client.Username
        FROM feedback
        INNER JOIN client ON client.ClientID = feedback.ClientID
        WHERE feedback.LawyerID = ?
        ORDER BY feedback.DateGiven DESC";

$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $lawyerId);
$stmt->execute();
$result = $stmt->get_result();

$comments = [];

while ($row = $result->fetch_assoc()) {
    $comments[] = [
        "username" => $row["Username"],
        "rate" => intval($row["Rate"]),
        "review" => $row["Review"],
        "date" => $row["DateGiven"]
    ];
}

echo json_encode($comments, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
$conn->close();
?>
