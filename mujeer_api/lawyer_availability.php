<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");

// preflight
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit;
}

require_once "config.php";

ini_set('display_errors', 1);
error_reporting(E_ALL);

// ===== قراءة جسم الطلب مرة واحدة فقط =====
$rawInput = file_get_contents("php://input");

// ===== Logging للتشخيص =====
file_put_contents('debug_availability.log', "=== New Request ===\n", FILE_APPEND);
file_put_contents('debug_availability.log', "Method: " . $_SERVER['REQUEST_METHOD'] . "\n", FILE_APPEND);
file_put_contents('debug_availability.log', "Raw input: " . $rawInput . "\n", FILE_APPEND);

// ===== Parse JSON =====
$input = json_decode($rawInput, true);

// إذا فشل JSON أو كان فاضي/مو Array (ممكن يكون form-data)
if (json_last_error() !== JSON_ERROR_NONE || !is_array($input)) {
    $input = $_POST;
}

file_put_contents('debug_availability.log', "Parsed input: " . print_r($input, true) . "\n", FILE_APPEND);

// الحصول على action من مصادر متعددة
$action = $input['action'] ?? ($_GET['action'] ?? '');
file_put_contents('debug_availability.log', "Action: $action\n", FILE_APPEND);

/**
 * Helper: throw if prepare failed
 */
function must_prepare($conn, $sql) {
    $stmt = $conn->prepare($sql);
    if (!$stmt) {
        throw new Exception("Prepare failed: " . $conn->error);
    }
    return $stmt;
}

/**
 * ✅ أكشن مطلوب لواجهة Flutter قبل الحذف
 * يرجع:
 * - booked_slots: قائمة الداتا تايم المحجوزة من المدخلات
 * - unbooked_slots: قائمة السلوُتس القابلة للحذف (بنفس شكل input)
 */
if ($action === 'check_booked_slots') {
    $lawyer_id = $input['lawyer_id'] ?? null;
    $slots = $input['slots'] ?? [];

    file_put_contents('debug_availability.log', "Check Booked Slots - Lawyer: $lawyer_id\n", FILE_APPEND);

    if (!$lawyer_id || empty($slots)) {
        echo json_encode(["success" => false, "message" => "Missing lawyer_id or slots"]);
        exit;
    }

    // جهز datetimes
    $datetimes = [];
    $mapInput = []; // للاحتفاظ بالمدخلات كما هي
    foreach ($slots as $slot) {
        $day = $slot['day'] ?? '';
        $time = $slot['time'] ?? '';
        if ($day && $time) {
            $dt = $day . ' ' . $time;
            $datetimes[] = $dt;
            $mapInput[] = ['day' => $day, 'time' => $time, 'dt' => $dt];
        }
    }

    if (empty($datetimes)) {
        echo json_encode(["success" => true, "booked_slots" => [], "unbooked_slots" => []]);
        exit;
    }

    try {
        $placeholders = implode(',', array_fill(0, count($datetimes), '?'));
        $sql = "SELECT `time` FROM timeslot WHERE lawyer_id = ? AND is_booked = 1 AND `time` IN ($placeholders)";
        $stmt = must_prepare($conn, $sql);

        $types = 'i' . str_repeat('s', count($datetimes));
        $params = array_merge([$types, $lawyer_id], $datetimes);

        // bind_param ديناميكي (بالمرجع)
        $refs = [];
        foreach ($params as $k => $v) { $refs[$k] = &$params[$k]; }
        call_user_func_array([$stmt, 'bind_param'], $refs);

        if (!$stmt->execute()) {
            throw new Exception("Execute failed: " . $stmt->error);
        }

        $result = $stmt->get_result();
        $booked = [];
        while ($row = $result->fetch_assoc()) {
            $booked[] = $row['time'];
        }
        $stmt->close();

        // ابني unbooked_slots بنفس شكل Flutter (day,time)
        $unbooked = [];
        foreach ($mapInput as $it) {
            if (!in_array($it['dt'], $booked, true)) {
                $unbooked[] = ['day' => $it['day'], 'time' => $it['time']];
            }
        }

        echo json_encode([
            "success" => true,
            "booked_slots" => $booked,
            "unbooked_slots" => $unbooked
        ]);
        exit;

    } catch (Exception $e) {
        echo json_encode(["success" => false, "message" => "Error: " . $e->getMessage()]);
        exit;
    }
}

// تحديث سعر المحامي
if ($action === 'update_price') {
    $lawyer_id = $input['lawyer_id'] ?? null;
    $price = $input['price'] ?? null;

    file_put_contents('debug_availability.log', "Update Price - Lawyer: $lawyer_id, Price: $price\n", FILE_APPEND);

    if (!$lawyer_id || $price === null) {
        echo json_encode(["success" => false, "message" => "Missing lawyer_id or price"]);
        exit;
    }

    try {
        $stmt = must_prepare($conn, "UPDATE lawyer SET price = ? WHERE LawyerID = ?");
        $stmt->bind_param("di", $price, $lawyer_id);

        if (!$stmt->execute()) {
            throw new Exception("Execute failed: " . $stmt->error);
        }

        echo json_encode(["success" => true, "message" => "Price updated successfully"]);
        $stmt->close();
        exit;

    } catch (Exception $e) {
        echo json_encode(["success" => false, "message" => "Database error: " . $e->getMessage()]);
        exit;
    }
}

// حفظ الأوقات
elseif ($action === 'save_availability') {
    file_put_contents('debug_availability.log', "Entered save_availability\n", FILE_APPEND);
    file_put_contents('debug_availability.log', "Availability count: " . count(($input['availability'] ?? [])) . "\n", FILE_APPEND);

    $lawyer_id = $input['lawyer_id'] ?? null;
    $availability = $input['availability'] ?? [];

    if (!$lawyer_id) {
        echo json_encode(["success" => false, "message" => "Missing lawyer_id"]);
        exit;
    }

    $conn->begin_transaction();
    file_put_contents('debug_availability.log', "Transaction started\n", FILE_APPEND);


    try {
        // 1) جلب الأوقات المحجوزة الحالية
        $booked_times = [];
        $check_stmt = must_prepare($conn, "SELECT `time` FROM timeslot WHERE lawyer_id = ? AND is_booked = 1");
        $check_stmt->bind_param("i", $lawyer_id);

        if (!$check_stmt->execute()) {
            throw new Exception("Check execute failed: " . $check_stmt->error);
        }

        $check_result = $check_stmt->get_result();
        while ($row = $check_result->fetch_assoc()) {
            $booked_times[] = $row['time'];
        }
        $check_stmt->close();
        file_put_contents('debug_availability.log', "Booked fetched\n", FILE_APPEND);

        // 2) حذف الأوقات غير المحجوزة فقط
        $delete_stmt = must_prepare($conn, "DELETE FROM timeslot WHERE lawyer_id = ? AND is_booked = 0");
        $delete_stmt->bind_param("i", $lawyer_id);

        if (!$delete_stmt->execute()) {
            throw new Exception("Delete execute failed: " . $delete_stmt->error);
        }
        $delete_stmt->close();
        file_put_contents('debug_availability.log', "Unbooked deleted\n", FILE_APPEND);

        // 3) إضافة الأوقات الجديدة (تخطي المحجوز)
        $inserted_count = 0;
        $skipped_booked = [];

        $insert_stmt = must_prepare($conn, "INSERT INTO timeslot (lawyer_id, `time`, is_booked) VALUES (?, ?, 0)");

        foreach ($availability as $slot) {
            $day = $slot['day'] ?? '';
            $time = $slot['time'] ?? '';

            if ($day && $time) {
                $datetime = $day . ' ' . $time;

                if (in_array($datetime, $booked_times, true)) {
                    $skipped_booked[] = $datetime;
                    continue;
                }

                $insert_stmt->bind_param("is", $lawyer_id, $datetime);

                if (!$insert_stmt->execute()) {
                    throw new Exception("Insert execute failed: " . $insert_stmt->error);
                }

                $inserted_count++;
            }
        }

        $insert_stmt->close();
        $conn->commit();
        file_put_contents('debug_availability.log', "Commit done\n", FILE_APPEND);

        $response = [
            "success" => true,
            "message" => "تم حفظ الإتاحة بنجاح",
            "inserted_count" => $inserted_count,
            "total_requested" => count($availability),
        ];

        if (!empty($skipped_booked)) {
            $response["warning"] = "تم تخطي " . count($skipped_booked) . " وقت لأنها محجوزة";
            $response["skipped_slots"] = $skipped_booked;
        }

        echo json_encode($response);
        exit;

    } catch (Exception $e) {
        $conn->rollback();
        file_put_contents('debug_availability.log', "save_availability ERROR: " . $e->getMessage() . "\n", FILE_APPEND);
        echo json_encode(["success" => false, "message" => "Error: " . $e->getMessage()]);
        exit;
    }
}

// جلب الأوقات الحالية (جميع الأوقات)
elseif ($action === 'get_availability') {
    $lawyer_id = $input['lawyer_id'] ?? ($_GET['lawyer_id'] ?? null);
    file_put_contents('debug_availability.log', "Get Availability - Lawyer: $lawyer_id\n", FILE_APPEND);

    if (!$lawyer_id) {
        echo json_encode(["success" => false, "message" => "Missing lawyer_id"]);
        exit;
    }

    try {
        $stmt = must_prepare($conn, "SELECT `time` FROM timeslot WHERE lawyer_id = ?");
        $stmt->bind_param("i", $lawyer_id);

        if (!$stmt->execute()) {
            throw new Exception("Execute failed: " . $stmt->error);
        }

        $result = $stmt->get_result();
        $availability = [];

        while ($row = $result->fetch_assoc()) {
            $datetime = $row['time']; // "YYYY-MM-DD HH:MM:SS"
            $parts = explode(' ', $datetime);
            $availability[] = [
                'day' => $parts[0] ?? '',
                'time' => $parts[1] ?? ''
            ];
        }

        $stmt->close();

        echo json_encode(["success" => true, "data" => $availability]);
        exit;

    } catch (Exception $e) {
        echo json_encode(["success" => false, "message" => "Error: " . $e->getMessage()]);
        exit;
    }
}

// جلب الأوقات غير المحجوزة فقط
elseif ($action === 'get_unbooked_availability') {
    $lawyer_id = $input['lawyer_id'] ?? ($_GET['lawyer_id'] ?? null);
    file_put_contents('debug_availability.log', "Get Unbooked Availability - Lawyer: $lawyer_id\n", FILE_APPEND);

    if (!$lawyer_id) {
        echo json_encode(["success" => false, "message" => "Missing lawyer_id"]);
        exit;
    }

    try {
        $stmt = must_prepare($conn, "SELECT `time` FROM timeslot WHERE lawyer_id = ? AND is_booked = 0");
        $stmt->bind_param("i", $lawyer_id);

        if (!$stmt->execute()) {
            throw new Exception("Execute failed: " . $stmt->error);
        }

        $result = $stmt->get_result();
        $availability = [];

        while ($row = $result->fetch_assoc()) {
            $datetime = $row['time'];
            $parts = explode(' ', $datetime);
            $availability[] = [
                'day' => $parts[0] ?? '',
                'time' => $parts[1] ?? ''
            ];
        }

        $stmt->close();

        echo json_encode(["success" => true, "data" => $availability]);
        exit;

    } catch (Exception $e) {
        echo json_encode(["success" => false, "message" => "Error: " . $e->getMessage()]);
        exit;
    }
}

// جلب السعر الحالي
elseif ($action === 'get_price') {
    $lawyer_id = $input['lawyer_id'] ?? ($_GET['lawyer_id'] ?? null);
    file_put_contents('debug_availability.log', "Get Price - Lawyer: $lawyer_id\n", FILE_APPEND);

    if (!$lawyer_id) {
        echo json_encode(["success" => false, "message" => "Missing lawyer_id"]);
        exit;
    }

    try {
        $stmt = must_prepare($conn, "SELECT price FROM lawyer WHERE LawyerID = ?");
        $stmt->bind_param("i", $lawyer_id);

        if (!$stmt->execute()) {
            throw new Exception("Execute failed: " . $stmt->error);
        }

        $result = $stmt->get_result();
        $row = $result->fetch_assoc();
        $stmt->close();

        echo json_encode(["success" => true, "price" => $row['price'] ?? 0.0]);
        exit;

    } catch (Exception $e) {
        echo json_encode(["success" => false, "message" => "Error: " . $e->getMessage()]);
        exit;
    }
}

// حذف جميع الأوقات غير المحجوزة
elseif ($action === 'delete_all') {
    $lawyer_id = $input['lawyer_id'] ?? null;
    file_put_contents('debug_availability.log', "Delete All - Lawyer: $lawyer_id\n", FILE_APPEND);

    if (!$lawyer_id) {
        echo json_encode(["success" => false, "message" => "Missing lawyer_id"]);
        exit;
    }

    try {
        $stmt = must_prepare($conn, "DELETE FROM timeslot WHERE lawyer_id = ? AND is_booked = 0");
        $stmt->bind_param("i", $lawyer_id);

        if (!$stmt->execute()) {
            throw new Exception("Execute failed: " . $stmt->error);
        }

        echo json_encode(["success" => true, "message" => "All unbooked availability deleted successfully"]);
        $stmt->close();
        exit;

    } catch (Exception $e) {
        echo json_encode(["success" => false, "message" => "Database error: " . $e->getMessage()]);
        exit;
    }
}

// حذف أوقات محددة
elseif ($action === 'delete_selected') {
    $lawyer_id = $input['lawyer_id'] ?? null;
    $slots_to_delete = $input['slots_to_delete'] ?? [];

    file_put_contents('debug_availability.log', "Delete Selected - Lawyer: $lawyer_id\n", FILE_APPEND);
    file_put_contents('debug_availability.log', "Slots to delete: " . print_r($slots_to_delete, true) . "\n", FILE_APPEND);

    if (!$lawyer_id || empty($slots_to_delete)) {
        echo json_encode(["success" => false, "message" => "Missing lawyer_id or slots to delete"]);
        exit;
    }

    $conn->begin_transaction();

    try {
        $delete_count = 0;
        $stmt = must_prepare($conn, "DELETE FROM timeslot WHERE lawyer_id = ? AND `time` = ? AND is_booked = 0");

        foreach ($slots_to_delete as $slot) {
            $day = $slot['day'] ?? '';
            $time = $slot['time'] ?? '';

            if ($day && $time) {
                $datetime = $day . ' ' . $time;
                $stmt->bind_param("is", $lawyer_id, $datetime);

                if (!$stmt->execute()) {
                    throw new Exception("Delete execute failed: " . $stmt->error);
                }

                $delete_count += $stmt->affected_rows;
            }
        }

        $stmt->close();
        $conn->commit();

        // لاحظي: حتى لو deleted_count = 0 نرجع success true لأن العملية تمت،
        // لكن نوضح السبب (ما كان فيه صفوف مطابقة).
        echo json_encode([
            "success" => true,
            "message" => "Selected slots deleted successfully",
            "deleted_count" => $delete_count
        ]);
        exit;

    } catch (Exception $e) {
        $conn->rollback();
        echo json_encode(["success" => false, "message" => "Error deleting selected slots: " . $e->getMessage()]);
        exit;
    }
}

// تحديث الأوقات المتبقية بعد الحذف
elseif ($action === 'update_remaining_slots') {
    $lawyer_id = $input['lawyer_id'] ?? null;
    $remaining_slots = $input['remaining_slots'] ?? [];

    file_put_contents('debug_availability.log', "Update Remaining Slots - Lawyer: $lawyer_id\n", FILE_APPEND);
    file_put_contents('debug_availability.log', "Remaining slots: " . print_r($remaining_slots, true) . "\n", FILE_APPEND);

    if (!$lawyer_id) {
        echo json_encode(["success" => false, "message" => "Missing lawyer_id"]);
        exit;
    }

    $conn->begin_transaction();

    try {
        $delete_stmt = must_prepare($conn, "DELETE FROM timeslot WHERE lawyer_id = ?");
        $delete_stmt->bind_param("i", $lawyer_id);

        if (!$delete_stmt->execute()) {
            throw new Exception("Failed to delete old availability: " . $delete_stmt->error);
        }
        $delete_stmt->close();

        if (!empty($remaining_slots)) {
            $insert_stmt = must_prepare($conn, "INSERT INTO timeslot (lawyer_id, `time`, is_booked) VALUES (?, ?, 0)");
            $inserted_count = 0;

            foreach ($remaining_slots as $slot) {
                $day = $slot['day'] ?? '';
                $time = $slot['time'] ?? '';
                if ($day && $time) {
                    $datetime = $day . ' ' . $time;
                    $insert_stmt->bind_param("is", $lawyer_id, $datetime);
                    if (!$insert_stmt->execute()) {
                        throw new Exception("Insert failed: " . $insert_stmt->error);
                    }
                    $inserted_count++;
                }
            }
            $insert_stmt->close();
        }

        $conn->commit();

        echo json_encode([
            "success" => true,
            "message" => "Remaining slots updated successfully",
            "remaining_count" => count($remaining_slots)
        ]);
        exit;

    } catch (Exception $e) {
        $conn->rollback();
        echo json_encode(["success" => false, "message" => "Error updating remaining slots: " . $e->getMessage()]);
        exit;
    }
}

// في حال لم يتم إرسال action
file_put_contents(
    'debug_availability.log',
    "No valid action found. Available actions: update_price, save_availability, get_availability, get_unbooked_availability, get_price, delete_all, delete_selected, update_remaining_slots, check_booked_slots\n",
    FILE_APPEND
);

echo json_encode([
    "success" => false,
    "message" => "No valid action found. Available actions: update_price, save_availability, get_availability, get_unbooked_availability, get_price, delete_all, delete_selected, update_remaining_slots, check_booked_slots"
]);
exit;
?>
