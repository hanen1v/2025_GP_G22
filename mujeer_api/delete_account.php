<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");


error_reporting(E_ALL);
ini_set('display_errors', 1);

require_once __DIR__ . '/config.php';

$raw  = file_get_contents("php://input");
$data = json_decode($raw, true);

if (!$data) {
    echo json_encode(["success" => false, "message" => "Invalid JSON"]);
    exit;
}



$required = ['userId','userType','password'];
foreach ($required as $f) {
    if (!isset($data[$f]) || $data[$f] === '') {
        echo json_encode(["success"=>false, "message"=>"Missing field: $f"], JSON_UNESCAPED_UNICODE);
        exit;
    }
}

$userId   = (int)$data['userId'];
$userType = strtolower(trim($data['userType']));
$password = $data['password'];
$force    = !empty($data['force']);   //  false

if (!in_array($userType, ['client','lawyer'], true)) {
    echo json_encode(["success"=>false, "message"=>"Invalid userType"], JSON_UNESCAPED_UNICODE);
    exit;
}



//  Username + PhoneNumber + Password + Points (  client)
if ($userType === 'client') {
    $stmtSel = $conn->prepare("
        SELECT ClientID AS id, Username, PhoneNumber, Password, Points
        FROM client
        WHERE ClientID = ?
        LIMIT 1
    ");
} else {
     $stmtSel = $conn->prepare("
        SELECT LawyerID AS id, Username, PhoneNumber, Password, Points
        FROM lawyer
        WHERE LawyerID = ?
        LIMIT 1
    ");
}

if (!$stmtSel) {
    echo json_encode([
        "success" => false,
        "message" => "Prepare(select) failed: " . $conn->error
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

$stmtSel->bind_param("i", $userId);
$stmtSel->execute();
$resSel = $stmtSel->get_result();

if (!$resSel || $resSel->num_rows === 0) {
    echo json_encode(["success"=>false, "message"=>"User not found"], JSON_UNESCAPED_UNICODE);
    $stmtSel->close();
    exit;
}

$row = $resSel->fetch_assoc();
$stmtSel->close();



if (!password_verify($password, $row['Password'])) {
    echo json_encode(["success"=>false, "message"=>"كلمة المرور غير صحيحة"], JSON_UNESCAPED_UNICODE);
    exit;
}



if ($userType === 'client') {

    // 1)  Active
    $qActive = $conn->query("
        SELECT 1 FROM appointment 
        WHERE ClientID = $userId AND Status = 'Active'
        LIMIT 1
    ");
    if ($qActive && $qActive->num_rows > 0) {
        echo json_encode([
            "success" => false,
            "code"    => "HAS_ACTIVE",
            "message" => "لا يمكن حذف الحساب لوجود مواعيد نشطة. الرجاء إكمالها أولاً."
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    // 2)  Upcoming
    $qUpcoming = $conn->query("
        SELECT 1 FROM appointment 
        WHERE ClientID = $userId AND Status = 'Upcoming'
        LIMIT 1
    ");
    if ($qUpcoming && $qUpcoming->num_rows > 0) {
        echo json_encode([
            "success" => false,
            "code"    => "HAS_UPCOMING",
            "message" => "لديك مواعيد قادمة، قم بإلغائها أولاً قبل حذف الحساب."
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    // 3) Points
    $points = (int)($row['Points'] ?? 0);
    if ($points > 0 && !$force) {
        echo json_encode([
            "success" => false,
            "code"    => "HAS_POINTS",
            "points"  => $points,
            "message" => "لديك مبلغ في المحفظة بقيمة ($points نقطة)، هل أنت متأكد من حذف الحساب؟ هذا المبلغ غير مسترد."
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    // 4) 
    $appsRes = $conn->query("SELECT AppointmentID FROM appointment WHERE ClientID = $userId");
    if ($appsRes) {
        while ($a = $appsRes->fetch_assoc()) {
            $aid = (int)$a['AppointmentID'];
            $conn->query("DELETE FROM consultation   WHERE AppointmentID = $aid");
            $conn->query("DELETE FROM contractreview WHERE AppointmentID = $aid");
        }
        $conn->query("DELETE FROM appointment WHERE ClientID = $userId");
    }

    // 5)
    $stmtDel = $conn->prepare("DELETE FROM client WHERE ClientID = ? LIMIT 1");
    if (!$stmtDel) {
        echo json_encode([
            "success" => false,
            "message" => "Prepare(delete) failed: " . $conn->error
        ], JSON_UNESCAPED_UNICODE);
        $conn->close();
        exit;
    }

    $stmtDel->bind_param("i", $userId);
    if (!$stmtDel->execute()) {
        echo json_encode([
            "success" => false,
            "message" => "Delete failed: " . $stmtDel->error
        ], JSON_UNESCAPED_UNICODE);
        $stmtDel->close();
        $conn->close();
        exit;
    }

    $stmtDel->close();

    echo json_encode([
        "success" => true,
        "message" => "تم حذف الحساب بنجاح"
    ], JSON_UNESCAPED_UNICODE);

    $conn->close();
    exit;
}




if ($userType === 'lawyer') {

    // 1)  Active ؟
    $qActive = $conn->query("
        SELECT 1 
        FROM appointment 
        WHERE LawyerID = $userId AND Status = 'Active'
        LIMIT 1
    ");
    if ($qActive && $qActive->num_rows > 0) {
        echo json_encode([
            "success" => false,
            "code"    => "LAWYER_HAS_ACTIVE",
            "message" => "لا يمكن حذف الحساب لوجود مواعيد نشطة. الرجاء إكمالها أولاً."
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    // 2)   Upcoming ؟
    $qUpcoming = $conn->query("
        SELECT 1 
        FROM appointment 
        WHERE LawyerID = $userId AND Status = 'Upcoming'
        LIMIT 1
    ");
    if ($qUpcoming && $qUpcoming->num_rows > 0) {
        echo json_encode([
            "success" => false,
            "code"    => "LAWYER_HAS_UPCOMING",
            "message" => "لديك مواعيد قادمة، قم بإكمالها أولاً."
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    // 3) 
    $points = (int)($row['Points'] ?? 0);
    if ($points > 0 && !$force) {
        echo json_encode([
            "success" => false,
            "code"    => "LAWYER_HAS_POINTS",
            "points"  => $points,
            "message" => "لديك مبلغ في المحفظة بقيمة ($points نقطة)، هل أنت متأكد من إيقاف الحساب؟ هذه النقاط غير مستردة."
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    // 4) 
    $emptyPhoto = ''; 

    $stmtSoft = $conn->prepare("
    UPDATE lawyer
    SET FullName    = CONCAT(FullName, ' (حساب محذوف)'),
        LawyerPhoto = ?,
        Status      = 'Rejected',
        Points      = 0
    WHERE LawyerID  = ?
    LIMIT 1
");

    if (!$stmtSoft) {
        echo json_encode([
            "success" => false,
            "message" => "Prepare failed: " . $conn->error
        ], JSON_UNESCAPED_UNICODE);
        $conn->close();
        exit;
    }

    $stmtSoft->bind_param("si", $emptyPhoto, $userId);

    if (!$stmtSoft->execute()) {
        echo json_encode([
            "success" => false,
            "message" => "Update failed: " . $stmtSoft->error
        ], JSON_UNESCAPED_UNICODE);
        $stmtSoft->close();
        $conn->close();
        exit;
    }

    $stmtSoft->close();

    echo json_encode([
        "success" => true,
        "message" => "تم إيقاف الحساب بنجاح"
    ], JSON_UNESCAPED_UNICODE);

    $conn->close();
    exit;
}

