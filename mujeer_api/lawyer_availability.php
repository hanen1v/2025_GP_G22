<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit;
}

require_once "config.php";

ini_set('display_errors', 1);
error_reporting(E_ALL);

// تسجيل البيانات للتصحيح
file_put_contents('debug_availability.log', "=== New Request ===\n", FILE_APPEND);
file_put_contents('debug_availability.log', "Method: " . $_SERVER['REQUEST_METHOD'] . "\n", FILE_APPEND);
file_put_contents('debug_availability.log', "Raw input: " . file_get_contents("php://input") . "\n", FILE_APPEND);

// الحصول على البيانات المدخلة
$input = json_decode(file_get_contents("php://input"), true);

// إذا فشل تحويل JSON، حاول مع POST العادي
if (json_last_error() !== JSON_ERROR_NONE) {
    $input = $_POST;
}

file_put_contents('debug_availability.log', "Parsed input: " . print_r($input, true) . "\n", FILE_APPEND);

// الحصول على action من مصادر متعددة
$action = $input['action'] ?? ($_GET['action'] ?? '');

file_put_contents('debug_availability.log', "Action: $action\n", FILE_APPEND);

if ($action === 'update_price') {
    $lawyer_id = $input['lawyer_id'] ?? null;
    $price = $input['price'] ?? null;

    file_put_contents('debug_availability.log', "Update Price - Lawyer: $lawyer_id, Price: $price\n", FILE_APPEND);

    if (!$lawyer_id || $price === null) {
        echo json_encode([
            "success" => false,
            "message" => "Missing lawyer_id or price"
        ]);
        exit;
    }

    $stmt = $conn->prepare("UPDATE lawyer SET price = ? WHERE LawyerID = ?");
    $stmt->bind_param("di", $price, $lawyer_id);

    if ($stmt->execute()) {
        echo json_encode([
            "success" => true,
            "message" => "Price updated successfully"
        ]);
    } else {
        echo json_encode([
            "success" => false,
            "message" => "Database error: " . $stmt->error
        ]);
    }

    $stmt->close();
    exit;
}

// حفظ الأوقات
elseif ($action === 'save_availability') {
    $lawyer_id = $input['lawyer_id'] ?? null;
    $availability = $input['availability'] ?? [];

    file_put_contents('debug_availability.log', "Save Availability - Lawyer: $lawyer_id\n", FILE_APPEND);
    file_put_contents('debug_availability.log', "Availability data: " . print_r($availability, true) . "\n", FILE_APPEND);

    if (!$lawyer_id || empty($availability)) {
        echo json_encode([
            "success" => false,
            "message" => "Missing lawyer_id or availability data"
        ]);
        exit;
    }

    // بدء transaction
    $conn->begin_transaction();

    try {
        // 1. حذف الأوقات القديمة أولاً
        $delete_stmt = $conn->prepare("DELETE FROM timeslot WHERE lawyer_id = ?");
        $delete_stmt->bind_param("i", $lawyer_id);
        
        if (!$delete_stmt->execute()) {
            throw new Exception("Failed to delete old availability: " . $delete_stmt->error);
        }
        $delete_stmt->close();

        // 2. إضافة الأوقات الجديدة
        $insert_stmt = $conn->prepare("INSERT INTO timeslot (lawyer_id, day, time) VALUES (?, ?, ?)");
        $inserted_count = 0;
        
        foreach ($availability as $slot) {
            $day = $slot['day'] ?? '';
            $time = $slot['time'] ?? '';
            
            if (!empty($day) && !empty($time)) {
                $insert_stmt->bind_param("iss", $lawyer_id, $day, $time);
                if ($insert_stmt->execute()) {
                    $inserted_count++;
                } else {
                    throw new Exception("Failed to insert availability: " . $insert_stmt->error);
                }
            }
        }
        
        $insert_stmt->close();
        
        // تأكيد العملية
        $conn->commit();
        
        echo json_encode([
            "success" => true,
            "message" => "Availability saved successfully",
            "inserted_count" => $inserted_count
        ]);
        
    } catch (Exception $e) {
        // تراجع في حالة الخطأ
        $conn->rollback();
        
        echo json_encode([
            "success" => false,
            "message" => "Error saving availability: " . $e->getMessage()
        ]);
    }
    exit;
}

// جلب الأوقات الحالية
elseif ($action === 'get_availability') {
    $lawyer_id = $input['lawyer_id'] ?? ($_GET['lawyer_id'] ?? null);

    file_put_contents('debug_availability.log', "Get Availability - Lawyer: $lawyer_id\n", FILE_APPEND);

    if (!$lawyer_id) {
        echo json_encode([
            "success" => false,
            "message" => "Missing lawyer_id"
        ]);
        exit;
    }

    $stmt = $conn->prepare("SELECT day, time FROM timeslot WHERE lawyer_id = ?");
    $stmt->bind_param("i", $lawyer_id);
    $stmt->execute();
    $result = $stmt->get_result();

    $availability = [];
    while ($row = $result->fetch_assoc()) {
        $availability[] = [
            'day' => $row['day'],
            'time' => $row['time']
        ];
    }

    $stmt->close();

    echo json_encode([
        "success" => true,
        "data" => $availability
    ]);
    exit;
}

// جلب السعر الحالي
elseif ($action === 'get_price') {
    $lawyer_id = $input['lawyer_id'] ?? ($_GET['lawyer_id'] ?? null);

    file_put_contents('debug_availability.log', "Get Price - Lawyer: $lawyer_id\n", FILE_APPEND);

    if (!$lawyer_id) {
        echo json_encode([
            "success" => false,
            "message" => "Missing lawyer_id"
        ]);
        exit;
    }

    $stmt = $conn->prepare("SELECT price FROM lawyer WHERE LawyerID = ?");
    $stmt->bind_param("i", $lawyer_id);
    $stmt->execute();
    $result = $stmt->get_result();
    $row = $result->fetch_assoc();

    $stmt->close();

    echo json_encode([
        "success" => true,
        "price" => $row['price'] ?? 0.0
    ]);
    exit;
}

// في حال لم يتم إرسال action
file_put_contents('debug_availability.log', "No valid action found. Available actions: update_price, save_availability, get_availability, get_price\n", FILE_APPEND);
echo json_encode([
    "success" => false,
    "message" => "No valid action found. Available actions: update_price, save_availability, get_availability, get_price"
]);
exit;