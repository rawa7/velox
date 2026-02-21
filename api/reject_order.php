<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Only allow POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode([
        'success' => false,
        'message' => 'Method not allowed. Only POST requests are accepted.'
    ]);
    exit();
}

// Include database configuration
include '../resources/config.php';
include '../attend/status_tracker.php';

// Get JSON input
$json_input = file_get_contents('php://input');
$data = json_decode($json_input, true);

// Validate input
if (!isset($data['customer_id']) || !isset($data['order_id'])) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Customer ID and Order ID are required.'
    ]);
    exit();
}

$customer_id = intval($data['customer_id']);
$order_id = intval($data['order_id']);

try {
    // START TRANSACTION for atomic rejection operation
    mysqli_autocommit($conn, false);
    
    // Get current order status with lock
    $verify_query = "SELECT * FROM items WHERE id = $order_id AND customer_id = $customer_id FOR UPDATE";
    $verify_result = query($verify_query);
    
    if (mysqli_num_rows($verify_result) == 0) {
        throw new Exception("Order not found or doesn't belong to this customer");
    }
    
    $order_data = mysqli_fetch_assoc($verify_result);
    $current_status = $order_data['status'];
    
    // Enhanced status validation: Only allow rejection for specific statuses
    if (!in_array($current_status, [2, 13])) {
        $status_query = "SELECT name FROM statue WHERE id = $current_status";
        $status_result = query($status_query);
        $status_name = 'Unknown';
        if (mysqli_num_rows($status_result) > 0) {
            $status_name = mysqli_fetch_assoc($status_result)['name'];
        }
        throw new Exception("Cannot reject order #$order_id. Current status: $status_name. Only orders with 'Price Changed' or 'Pending' status can be rejected.");
    }
    
    // Force status to 6 (rejected)
    $rejected_status = 6;
    
    // Final validation: Re-check order status before update
    $final_check_query = "SELECT status FROM items WHERE id = $order_id AND customer_id = $customer_id";
    $final_check_result = query($final_check_query);
    $final_order_data = mysqli_fetch_assoc($final_check_result);
    
    if ($final_order_data['status'] != $current_status) {
        throw new Exception("Order status changed during processing. Please refresh and try again.");
    }
    
    // Atomic update: Update with conditions to prevent race conditions
    $reject_query = "UPDATE items SET status = $rejected_status WHERE id = $order_id AND customer_id = $customer_id AND status = $current_status";
    $update_result = query($reject_query);
    
    // Verify the update
    if (!$update_result || mysqli_affected_rows($conn) == 0) {
        throw new Exception("Failed to update order status. Order may have been modified by another process.");
    }
    
    // Double check: Verify the status was set correctly
    $verify_update_query = "SELECT status FROM items WHERE id = $order_id AND customer_id = $customer_id";
    $verify_update_result = query($verify_update_query);
    $updated_order = mysqli_fetch_assoc($verify_update_result);
    
    if ($updated_order['status'] != $rejected_status) {
        throw new Exception("Status update verification failed. Expected status $rejected_status, got " . $updated_order['status']);
    }
    
    // Commit the transaction
    mysqli_commit($conn);
    
    // Log successful rejection
    logStatusChange($order_id, $current_status, $rejected_status, "Customer rejected via API - Enhanced validation completed");
    
    // Reset autocommit
    mysqli_autocommit($conn, true);
    
    // Return success response
    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => "Order #$order_id has been rejected and returned for re-negotiation.",
        'data' => [
            'order_id' => $order_id,
            'new_status' => $rejected_status
        ]
    ]);
    
} catch (Exception $e) {
    // Rollback transaction on any error
    mysqli_rollback($conn);
    mysqli_autocommit($conn, true);
    
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
}

// Close database connection
mysqli_close($conn);
?>

