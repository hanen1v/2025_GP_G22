<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);
require_once __DIR__ . '/config.php';

header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

if (!isset($_GET['id'])) {
    echo json_encode(["error" => "No lawyer ID provided"]);
    exit;
}

$lawyerId = intval($_GET['id']);


$sql = "SELECT Rate FROM feedback WHERE LawyerID = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $lawyerId);
$stmt->execute();
$result = $stmt->get_result();

if (!$result || $result->num_rows === 0) {
    echo json_encode([
        "average" => 0,
        "count" => 0,
        "stars" => [
            "5" => 0,
            "4" => 0,
            "3" => 0,
            "2" => 0,
            "1" => 0
        ]
    ]);
    exit;
}

$starsCount = [
    "5" => 0,
    "4" => 0,
    "3" => 0,
    "2" => 0,
    "1" => 0
];

$total = 0;
$sum   = 0;

while ($row = $result->fetch_assoc()) {
    $r = intval($row['Rate']);
    if ($r >= 1 && $r <= 5) {
        $starsCount[(string)$r]++;
        $sum += $r;
        $total++;
    }
}

$average = $total > 0 ? round($sum / $total, 2) : 0;

echo json_encode([
    "average" => $average,
    "count"   => $total,
    "stars"   => $starsCount
]);

$conn->close();
?>

