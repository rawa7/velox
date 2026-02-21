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
    // START TRANSACTION for atomic operation
    mysqli_autocommit($conn, false);
    
    // Get current order status and details with FOR UPDATE lock
    $verify_query = "SELECT * FROM items WHERE id = $order_id AND customer_id = $customer_id FOR UPDATE";
    $verify_result = query($verify_query);
    
    if (mysqli_num_rows($verify_result) == 0) {
        throw new Exception("Order not found or doesn't belong to this customer");
    }
    
    $order_data = mysqli_fetch_assoc($verify_result);
    $current_status = $order_data['status'];
    $order_total = floatval($order_data['totalprice'] ?? $order_data['itemprice'] ?? 0);
    
    // Validate order total
    if ($order_total <= 0) {
        throw new Exception("Invalid order total. Orders with zero or negative amounts cannot be accepted.");
    }
    
    // Enhanced status validation: Only allow acceptance for specific statuses
    if (!in_array($current_status, [2, 13])) {
        $status_query = "SELECT name FROM statue WHERE id = $current_status";
        $status_result = query($status_query);
        $status_name = 'Unknown';
        if (mysqli_num_rows($status_result) > 0) {
            $status_name = mysqli_fetch_assoc($status_result)['name'];
        }
        throw new Exception("Cannot accept order #$order_id. Current status: $status_name. Only orders with 'Price Changed' or 'Pending' status can be accepted.");
    }
    
    // Get fresh customer data with lock
    $customer_query = "SELECT b.usertype, ut.name as usertype_name, ut.limitt as debt_limit 
                      FROM buyer b 
                      LEFT JOIN usertype ut ON b.usertype = ut.id 
                      WHERE b.id = $customer_id FOR UPDATE";
    $customer_result = query($customer_query);
    
    if (mysqli_num_rows($customer_result) == 0) {
        throw new Exception("Customer account not found. Please contact support.");
    }
    
    $customer_data = mysqli_fetch_assoc($customer_result);
    $debt_limit = floatval($customer_data['debt_limit'] ?? 0);
    $usertype_name = $customer_data['usertype_name'] ?? 'Unknown';
    
    // Validate debt limit
    if ($debt_limit < 0) {
        throw new Exception("Account configuration error. Please contact support.");
    }
    
    // Calculate balance
    $balance_query = "SELECT 
                    (SELECT COALESCE(SUM(amount), 0) FROM buyerpay WHERE buyerid = $customer_id) -
                    (SELECT COALESCE(SUM(totalprice), 0) FROM items WHERE customer_id = $customer_id AND paymentstatus = 1) 
                    AS available_balance";
    $balance_result = query($balance_query);
    $current_balance = floatval(mysqli_fetch_assoc($balance_result)['available_balance'] ?? 0);
    
    // Calculate unpaid orders
    $approved_unpaid_query = "SELECT COALESCE(SUM(totalprice), 0) as approved_unpaid 
                            FROM items 
                            WHERE customer_id = $customer_id 
                            AND status IN (3, 4, -1, 16, 17, 19) 
                            AND paymentstatus = 0";
    $approved_unpaid_result = query($approved_unpaid_query);
    $approved_unpaid_total = floatval(mysqli_fetch_assoc($approved_unpaid_result)['approved_unpaid'] ?? 0);
    
    // Calculate available capacity
    $available_capacity = $current_balance + $debt_limit - $approved_unpaid_total;
    
    // Validate capacity calculation
    if (!is_numeric($available_capacity) || !is_finite($available_capacity)) {
        throw new Exception("Error calculating account capacity. Please contact support.");
    }
    
    // Main balance validation
    if ($order_total > $available_capacity) {
        $detailed_error = "INSUFFICIENT FUNDS - Order cannot be accepted.\n";
        $detailed_error .= "Order Total: $" . number_format($order_total, 2) . "\n";
        $detailed_error .= "Available Capacity: $" . number_format($available_capacity, 2) . "\n";
        $detailed_error .= "Current Balance: $" . number_format($current_balance, 2) . "\n";
        $detailed_error .= "Account Type: " . $usertype_name . " (Debt Limit: $" . number_format($debt_limit, 2) . ")\n";
        $detailed_error .= "Unpaid Orders: $" . number_format($approved_unpaid_total, 2);
        
        throw new Exception($detailed_error);
    }
    
    // Paranoid balance check
    $paranoid_balance_check = "SELECT 
                             (SELECT COALESCE(SUM(amount), 0) FROM buyerpay WHERE buyerid = $customer_id) as total_payments,
                             (SELECT COALESCE(SUM(totalprice), 0) FROM items WHERE customer_id = $customer_id AND paymentstatus = 1) as total_paid_items";
    $paranoid_result = query($paranoid_balance_check);
    $paranoid_data = mysqli_fetch_assoc($paranoid_result);
    $paranoid_balance = floatval($paranoid_data['total_payments']) - floatval($paranoid_data['total_paid_items']);
    $paranoid_capacity = $paranoid_balance + $debt_limit - $approved_unpaid_total;
    
    if (abs($paranoid_capacity - $available_capacity) > 0.01) {
        throw new Exception("Balance calculation error detected. Please contact support.");
    }
    
    if ($order_total > $paranoid_capacity) {
        throw new Exception("Paranoid balance check failed - insufficient funds.");
    }
    
    // Security check: prevent severely indebted customers
    if ($current_balance < -1000 && $order_total > 50) {
        throw new Exception("Account requires payment before new orders can be approved. Please contact support.");
    }
    
    // Large order check
    if ($order_total > 10000) {
        throw new Exception("Large orders require manual approval by admin. Please contact support.");
    }
    
    // Final status check before update
    $final_check_query = "SELECT status FROM items WHERE id = $order_id AND customer_id = $customer_id";
    $final_check_result = query($final_check_query);
    $final_order_data = mysqli_fetch_assoc($final_check_result);
    
    if ($final_order_data['status'] != $current_status) {
        throw new Exception("Order status changed during processing. Please refresh and try again.");
    }
    
    // Update status to approved
    $approved_status = 3;
    $accept_query = "UPDATE items SET status = $approved_status WHERE id = $order_id AND customer_id = $customer_id AND status = $current_status";
    $update_result = query($accept_query);
    
    // Verify the update
    if (!$update_result || mysqli_affected_rows($conn) == 0) {
        throw new Exception("Failed to update order status. Order may have been modified by another process.");
    }
    
    // Commit the transaction
    mysqli_commit($conn);
    
    // Log successful acceptance
    logStatusChange($order_id, $current_status, $approved_status, "Customer accepted via API - Enhanced validation passed");
    
    // Reset autocommit
    mysqli_autocommit($conn, true);
    
    // Return success response with properly formatted decimals
    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => "Order #$order_id has been accepted and moved to approved status! Payment of $" . number_format($order_total, 2) . " will be processed when you pick up the item at delivery.",
        'data' => [
            'order_id' => $order_id,
            'new_status' => $approved_status,
            'order_total' => round($order_total, 2),
            'available_capacity' => round($available_capacity, 2),
            'current_balance' => round($current_balance, 2)
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

