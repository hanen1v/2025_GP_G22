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

file_put_contents('debug_availability.log', "=== New Request ===\n", FILE_APPEND);
file_put_contents('debug_availability.log', "Method: " . $_SERVER['REQUEST_METHOD'] . "\n", FILE_APPEND);
file_put_contents('debug_availability.log', "Raw input: " . file_get_contents("php://input") . "\n", FILE_APPEND);

$input = json_decode(file_get_contents("php://input"), true);

if (json_last_error() !== JSON_ERROR_NONE) {
    $input = $_POST;
}

file_put_contents('debug_availability.log', "Parsed input: " . print_r($input, true) . "\n", FILE_APPEND);

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

    $conn->begin_transaction();

    try {
        $delete_stmt = $conn->prepare("DELETE FROM timeslot WHERE lawyer_id = ?");
        $delete_stmt->bind_param("i", $lawyer_id);
        
        if (!$delete_stmt->execute()) {
            throw new Exception("Failed to delete old availability: " . $delete_stmt->error);
        }
        $delete_stmt->close();

        $insert_stmt = $conn->prepare("INSERT INTO timeslot (lawyer_id, time, is_booked) VALUES (?, ?, 0)");
        $inserted_count = 0;
        
        foreach ($availability as $slot) {
            $day = $slot['day'] ?? '';
            $time = $slot['time'] ?? '';
            
            $datetime = $day . ' ' . $time;
            
            if (!empty($day) && !empty($time)) {
                $insert_stmt->bind_param("is", $lawyer_id, $datetime);
                if ($insert_stmt->execute()) {
                    $inserted_count++;
                } else {
                    throw new Exception("Failed to insert availability: " . $insert_stmt->error);
                }
            }
        }
        
        $insert_stmt->close();
        
        $conn->commit();
        
        echo json_encode([
            "success" => true,
            "message" => "Availability saved successfully",
            "inserted_count" => $inserted_count
        ]);
        
    } catch (Exception $e) {
        $conn->rollback();
        
        echo json_encode([
            "success" => false,
            "message" => "Error saving availability: " . $e->getMessage()
        ]);
    }
    exit;
}

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

    $stmt = $conn->prepare("SELECT time FROM timeslot WHERE lawyer_id = ? AND is_booked = 0");
    $stmt->bind_param("i", $lawyer_id);
    $stmt->execute();
    $result = $stmt->get_result();

    $availability = [];
    while ($row = $result->fetch_assoc()) {
        $datetime = $row['time'];
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
        
        $conn->commit();
        
        echo json_encode([
            "success" => true,
            "message" => "Selected slots deleted successfully",
            "deleted_count" => $delete_count
        ]);
        
    } catch (Exception $e) {
        $conn->rollback();
        
        echo json_encode([
            "success" => false,
            "message" => "Error deleting selected slots: " . $e->getMessage()
        ]);
    }
    exit;
}

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
        $delete_stmt = $conn->prepare("DELETE FROM timeslot WHERE lawyer_id = ?");
        $delete_stmt->bind_param("i", $lawyer_id);
        
        if (!$delete_stmt->execute()) {
            throw new Exception("Failed to delete old availability: " . $delete_stmt->error);
        }
        $delete_stmt->close();

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
        
        $conn->commit();
        
        echo json_encode([
            "success" => true,
            "message" => "Remaining slots updated successfully",
            "remaining_count" => count($remaining_slots)
        ]);
        
    } catch (Exception $e) {
        $conn->rollback();
        
        echo json_encode([
            "success" => false,
            "message" => "Error updating remaining slots: " . $e->getMessage()
        ]);
    }
    exit;
}

file_put_contents('debug_availability.log', "No valid action found. Available actions: update_price, save_availability, get_availability, get_unbooked_availability, get_price, delete_all, delete_selected, update_remaining_slots\n", FILE_APPEND);
echo json_encode([
    "success" => false,
    "message" => "No valid action found. Available actions: update_price, save_availability, get_availability, get_unbooked_availability, get_price, delete_all, delete_selected, update_remaining_slots"
]);
exit;
?>
