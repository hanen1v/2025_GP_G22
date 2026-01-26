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

// تحديث سعر المحامي
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

    if (!$lawyer_id) {
        echo json_encode(["success" => false, "message" => "Missing lawyer_id"]);
        exit;
    }

    $conn->begin_transaction();

    try {
        // 1. جلب جميع الأوقات المحجوزة الحالية
        $booked_times = [];
        $check_stmt = $conn->prepare("
            SELECT time 
            FROM timeslot 
            WHERE lawyer_id = ? 
            AND is_booked = 1
        ");
        $check_stmt->bind_param("i", $lawyer_id);
        $check_stmt->execute();
        $check_result = $check_stmt->get_result();
        
        while ($row = $check_result->fetch_assoc()) {
            $booked_times[] = $row['time'];
        }
        $check_stmt->close();

        // 2. حذف الأوقات غير المحجوزة فقط
        $delete_stmt = $conn->prepare("
            DELETE FROM timeslot 
            WHERE lawyer_id = ? 
            AND is_booked = 0
        ");
        $delete_stmt->bind_param("i", $lawyer_id);
        $delete_stmt->execute();
        $delete_stmt->close();

        // 3. إضافة الأوقات الجديدة مع استثناء المحجوزة
        $inserted_count = 0;
        $skipped_booked = [];
        
        foreach ($availability as $slot) {
            $day = $slot['day'] ?? '';
            $time = $slot['time'] ?? '';
            
            if (!empty($day) && !empty($time)) {
                $datetime = $day . ' ' . $time;
                
                // تحقق إذا كان الوقت محجوزاً
                if (in_array($datetime, $booked_times)) {
                    $skipped_booked[] = $datetime;
                    continue; // تخطي هذا الوقت
                }
                
                // إضافة الوقت غير المحجوز
                $insert_stmt = $conn->prepare("
                    INSERT INTO timeslot (lawyer_id, time, is_booked) 
                    VALUES (?, ?, 0)
                ");
                $insert_stmt->bind_param("is", $lawyer_id, $datetime);
                
                if ($insert_stmt->execute()) {
                    $inserted_count++;
                }
                $insert_stmt->close();
            }
        }
        
        $conn->commit();
        
        $response = [
            "success" => true,
            "message" => "تم حفظ الإتاحة بنجاح",
            "inserted_count" => $inserted_count,
            "total_requested" => count($availability)
        ];
        
        if (!empty($skipped_booked)) {
            $response['warning'] = "تم تخطي " . count($skipped_booked) . " وقت لأنها محجوزة";
            $response['skipped_slots'] = $skipped_booked;
        }
        
        echo json_encode($response);
        
    } catch (Exception $e) {
        $conn->rollback();
        echo json_encode([
            "success" => false,
            "message" => "Error: " . $e->getMessage()
        ]);
    }
    exit;
}

// جلب الأوقات الحالية (جميع الأوقات)
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

    $stmt = $conn->prepare("SELECT time FROM timeslot WHERE lawyer_id = ?");
    $stmt->bind_param("i", $lawyer_id);
    $stmt->execute();
    $result = $stmt->get_result();

    $availability = [];
    while ($row = $result->fetch_assoc()) {
        $datetime = $row['time'];
        // فصل التاريخ والوقت
        $date_time_parts = explode(' ', $datetime);
        $availability[] = [
            'day' => $date_time_parts[0] ?? '',
            'time' => $date_time_parts[1] ?? ''
        ];
    }

    $stmt->close();

    echo json_encode([
        "success" => true,
        "data" => $availability
    ]);
    exit;
}

// جلب الأوقات غير المحجوزة فقط
elseif ($action === 'get_unbooked_availability') {
    $lawyer_id = $input['lawyer_id'] ?? ($_GET['lawyer_id'] ?? null);

    file_put_contents('debug_availability.log', "Get Unbooked Availability - Lawyer: $lawyer_id\n", FILE_APPEND);

    if (!$lawyer_id) {
        echo json_encode([
            "success" => false,
            "message" => "Missing lawyer_id"
        ]);
        exit;
    }

    // جلب الأوقات غير المحجوزة (is_booked = 0)
    $stmt = $conn->prepare("SELECT time FROM timeslot WHERE lawyer_id = ? AND is_booked = 0");
    $stmt->bind_param("i", $lawyer_id);
    $stmt->execute();
    $result = $stmt->get_result();

    $availability = [];
    while ($row = $result->fetch_assoc()) {
        $datetime = $row['time'];
        // فصل التاريخ والوقت
        $date_time_parts = explode(' ', $datetime);
        $availability[] = [
            'day' => $date_time_parts[0] ?? '',
            'time' => $date_time_parts[1] ?? ''
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

// حذف جميع الأوقات غير المحجوزة
elseif ($action === 'delete_all') {
    $lawyer_id = $input['lawyer_id'] ?? null;

    file_put_contents('debug_availability.log', "Delete All - Lawyer: $lawyer_id\n", FILE_APPEND);

    if (!$lawyer_id) {
        echo json_encode([
            "success" => false,
            "message" => "Missing lawyer_id"
        ]);
        exit;
    }

    $stmt = $conn->prepare("DELETE FROM timeslot WHERE lawyer_id = ? AND is_booked = 0");
    $stmt->bind_param("i", $lawyer_id);

    if ($stmt->execute()) {
        echo json_encode([
            "success" => true,
            "message" => "All unbooked availability deleted successfully"
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

// حذف أوقات محددة
elseif ($action === 'delete_selected') {
    $lawyer_id = $input['lawyer_id'] ?? null;
    $slots_to_delete = $input['slots_to_delete'] ?? [];

    file_put_contents('debug_availability.log', "Delete Selected - Lawyer: $lawyer_id\n", FILE_APPEND);
    file_put_contents('debug_availability.log', "Slots to delete: " . print_r($slots_to_delete, true) . "\n", FILE_APPEND);

    if (!$lawyer_id || empty($slots_to_delete)) {
        echo json_encode([
            "success" => false,
            "message" => "Missing lawyer_id or slots to delete"
        ]);
        exit;
    }

    // بدء transaction
    $conn->begin_transaction();

    try {
        $delete_count = 0;
        
        foreach ($slots_to_delete as $slot) {
            $day = $slot['day'] ?? '';
            $time = $slot['time'] ?? '';
            
            if (!empty($day) && !empty($time)) {
                $datetime = $day . ' ' . $time;
                $stmt = $conn->prepare("DELETE FROM timeslot WHERE lawyer_id = ? AND time = ? AND is_booked = 0");
                $stmt->bind_param("is", $lawyer_id, $datetime);
                
                if ($stmt->execute()) {
                    $delete_count += $stmt->affected_rows;
                }
                $stmt->close();
            }
        }
        
        // تأكيد العملية
        $conn->commit();
        
        echo json_encode([
            "success" => true,
            "message" => "Selected slots deleted successfully",
            "deleted_count" => $delete_count
        ]);
        
    } catch (Exception $e) {
        // تراجع في حالة الخطأ
        $conn->rollback();
        
        echo json_encode([
            "success" => false,
            "message" => "Error deleting selected slots: " . $e->getMessage()
        ]);
    }
    exit;
}

// تحديث الأوقات المتبقية بعد الحذف
elseif ($action === 'update_remaining_slots') {
    $lawyer_id = $input['lawyer_id'] ?? null;
    $remaining_slots = $input['remaining_slots'] ?? [];

    file_put_contents('debug_availability.log', "Update Remaining Slots - Lawyer: $lawyer_id\n", FILE_APPEND);
    file_put_contents('debug_availability.log', "Remaining slots: " . print_r($remaining_slots, true) . "\n", FILE_APPEND);

    if (!$lawyer_id) {
        echo json_encode([
            "success" => false,
            "message" => "Missing lawyer_id"
        ]);
        exit;
    }

    // بدء transaction
    $conn->begin_transaction();

    try {
        // 1. حذف جميع الأوقات الحالية
        $delete_stmt = $conn->prepare("DELETE FROM timeslot WHERE lawyer_id = ?");
        $delete_stmt->bind_param("i", $lawyer_id);
        
        if (!$delete_stmt->execute()) {
            throw new Exception("Failed to delete old availability: " . $delete_stmt->error);
        }
        $delete_stmt->close();

        // 2. إضافة الأوقات المتبقية فقط
        if (!empty($remaining_slots)) {
            $insert_stmt = $conn->prepare("INSERT INTO timeslot (lawyer_id, time, is_booked) VALUES (?, ?, 0)");
            $inserted_count = 0;
            
            foreach ($remaining_slots as $slot) {
                $day = $slot['day'] ?? '';
                $time = $slot['time'] ?? '';
                
                if (!empty($day) && !empty($time)) {
                    $datetime = $day . ' ' . $time;
                    $insert_stmt->bind_param("is", $lawyer_id, $datetime);
                    if ($insert_stmt->execute()) {
                        $inserted_count++;
                    }
                }
            }
            
            $insert_stmt->close();
        }
        
        // تأكيد العملية
        $conn->commit();
        
        echo json_encode([
            "success" => true,
            "message" => "Remaining slots updated successfully",
            "remaining_count" => count($remaining_slots)
        ]);
        
    } catch (Exception $e) {
        // تراجع في حالة الخطأ
        $conn->rollback();
        
        echo json_encode([
            "success" => false,
            "message" => "Error updating remaining slots: " . $e->getMessage()
        ]);
    }
    exit;
}

// في حال لم يتم إرسال action
file_put_contents('debug_availability.log', "No valid action found. Available actions: update_price, save_availability, get_availability, get_unbooked_availability, get_price, delete_all, delete_selected, update_remaining_slots\n", FILE_APPEND);
echo json_encode([
    "success" => false,
    "message" => "No valid action found. Available actions: update_price, save_availability, get_availability, get_unbooked_availability, get_price, delete_all, delete_selected, update_remaining_slots"
]);
exit;
?>