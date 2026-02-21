<?php
/**
 * Notification Center
 * 
 * Sends database notifications AND real push notifications via FCM
 * Can be triggered manually or via cron job
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

// Include required files
require_once __DIR__ . '/../resources/config.php';
require_once __DIR__ . '/fcm_helper.php';
require_once __DIR__ . '/notification_helper.php';

// ============================================
// NOTIFICATION SENDING FUNCTION
// ============================================

/**
 * Send notification (both database and FCM push)
 * 
 * @param int $customer_id Customer ID
 * @param string $title Notification title
 * @param string $message Notification message
 * @param string $type Notification type
 * @param int|null $related_id Related entity ID
 * @param string|null $related_type Related entity type
 * @return array Result with database and FCM status
 */
function sendCompleteNotification($customer_id, $title, $message, $type = 'general', $related_id = null, $related_type = null) {
    global $conn;
    
    $result = [
        'customer_id' => $customer_id,
        'database' => false,
        'fcm' => false,
        'fcm_details' => null,
        'skipped' => false,
        'skip_reason' => null
    ];
    
    // Check if customer has bronze account (usertype = 5)
    // Bronze accounts should NOT receive any notifications
    $usertype_check = mysqli_query($conn, "SELECT usertype FROM buyer WHERE id = " . intval($customer_id));
    if ($usertype_check && $usertype_row = mysqli_fetch_assoc($usertype_check)) {
        if (intval($usertype_row['usertype']) === 5) {
            // Skip notification for bronze accounts
            $result['skipped'] = true;
            $result['skip_reason'] = 'Bronze account - notifications disabled';
            return $result;
        }
    }
    
    // 1. Save to database
    $notification_id = sendNotification($customer_id, $title, $message, $type, $related_id, $related_type);
    if ($notification_id) {
        $result['database'] = true;
        $result['notification_id'] = $notification_id;
    }
    
    // 2. Send FCM push notification
    $data = [
        'notification_id' => (string)$notification_id,
        'type' => $type,
    ];
    if ($related_id) $data['related_id'] = (string)$related_id;
    if ($related_type) $data['related_type'] = $related_type;
    
    $fcmResult = sendFirebaseNotificationToCustomer($conn, $customer_id, $title, $message, $data);
    $result['fcm'] = $fcmResult['success'];
    $result['fcm_details'] = $fcmResult;
    
    return $result;
}

// ============================================
// NOTIFICATION CAMPAIGNS
// ============================================

/**
 * Notify customers with orders in specific status
 * Sends individual notification for EACH order
 */
function notifyOrdersByStatus($status_id, $custom_title = null, $custom_message = null) {
    global $conn;
    
    $status_id = intval($status_id);
    
    // Get status name
    $status_query = "SELECT name FROM statue WHERE id = $status_id";
    $status_result = mysqli_query($conn, $status_query);
    $status_name = 'Unknown';
    if ($status_result && mysqli_num_rows($status_result) > 0) {
        $status_name = mysqli_fetch_assoc($status_result)['name'];
    }
    
    // Get ALL orders with this status (not grouped - one notification per order)
    // Exclude bronze accounts (usertype = 5)
    $query = "SELECT i.id as order_id, i.customer_id, b.name as customer_name,
              i.size, i.qty, i.totalprice
              FROM items i
              LEFT JOIN buyer b ON i.customer_id = b.id
              WHERE i.status = $status_id
              AND (b.usertype IS NULL OR b.usertype != 5)
              ORDER BY i.customer_id, i.id";
    
    $result = mysqli_query($conn, $query);
    
    $sent = [];
    $failed = [];
    $total_notifications = 0;
    
    while ($row = mysqli_fetch_assoc($result)) {
        $order_id = intval($row['order_id']);
        $customer_id = intval($row['customer_id']);
        $customer_name = $row['customer_name'];
        $size = $row['size'];
        $qty = $row['qty'];
        $totalprice = $row['totalprice'];
        
        // Create title and message for THIS specific order
        $title = $custom_title ?: "Order #$order_id Status Update";
        
        if ($custom_message) {
            // If custom message is provided, use it but replace placeholders
            $message = str_replace(
                ['{order_id}', '{status}', '{size}', '{qty}'],
                [$order_id, $status_name, $size, $qty],
                $custom_message
            );
        } else {
            // Default message for individual order
            $message = "Your order #$order_id is currently in '$status_name' status.";
            if ($size) $message .= " Size: $size.";
            if ($qty > 1) $message .= " Quantity: $qty.";
        }
        
        // Send notification for THIS order
        $sendResult = sendCompleteNotification(
            $customer_id,
            $title,
            $message,
            'order',
            $order_id,
            'order'
        );
        
        $total_notifications++;
        
        if ($sendResult['database'] || $sendResult['fcm']) {
            $sent[] = [
                'order_id' => $order_id,
                'customer_id' => $customer_id,
                'customer_name' => $customer_name,
                'result' => $sendResult
            ];
        } else {
            $failed[] = [
                'order_id' => $order_id,
                'customer_id' => $customer_id,
                'customer_name' => $customer_name
            ];
        }
    }
    
    // Count unique customers
    $unique_customers = [];
    foreach ($sent as $item) {
        $unique_customers[$item['customer_id']] = true;
    }
    foreach ($failed as $item) {
        $unique_customers[$item['customer_id']] = true;
    }
    
    return [
        'status_id' => $status_id,
        'status_name' => $status_name,
        'total_orders' => $total_notifications,
        'total_customers' => count($unique_customers),
        'sent' => $sent,
        'failed' => $failed
    ];
}

/**
 * Notify all customers with pending payments
 */
function notifyPendingPayments() {
    global $conn;
    
    // Get customers with unpaid approved orders
    // Exclude bronze accounts (usertype = 5)
    $query = "SELECT DISTINCT i.customer_id, b.name as customer_name,
              COUNT(i.id) as unpaid_count,
              SUM(i.totalprice) as total_amount
              FROM items i
              LEFT JOIN buyer b ON i.customer_id = b.id
              WHERE i.status IN (3, 4, -1, 16, 17, 19) 
              AND i.paymentstatus = 0
              AND (b.usertype IS NULL OR b.usertype != 5)
              GROUP BY i.customer_id, b.name
              HAVING total_amount > 0";
    
    $result = mysqli_query($conn, $query);
    $sent = [];
    
    while ($row = mysqli_fetch_assoc($result)) {
        $customer_id = intval($row['customer_id']);
        $customer_name = $row['customer_name'];
        $unpaid_count = intval($row['unpaid_count']);
        $total_amount = floatval($row['total_amount']);
        
        $title = "Payment Reminder";
        $message = "You have $unpaid_count order(s) awaiting payment totaling $" . number_format($total_amount, 2) . ". Please make payment to proceed with delivery.";
        
        $sendResult = sendCompleteNotification(
            $customer_id,
            $title,
            $message,
            'payment'
        );
        
        $sent[] = [
            'customer_id' => $customer_id,
            'customer_name' => $customer_name,
            'unpaid_count' => $unpaid_count,
            'total_amount' => $total_amount,
            'result' => $sendResult
        ];
    }
    
    return [
        'total_customers' => count($sent),
        'sent' => $sent
    ];
}

/**
 * Send custom announcement to all active customers
 */
function sendAnnouncementToAll($title, $message) {
    global $conn;
    
    // Exclude bronze accounts (usertype = 5) from announcements
    $query = "SELECT id, name FROM buyer WHERE is_active = 1 AND (usertype IS NULL OR usertype != 5)";
    $result = mysqli_query($conn, $query);
    
    $sent = [];
    $failed = [];
    
    while ($row = mysqli_fetch_assoc($result)) {
        $customer_id = intval($row['id']);
        $customer_name = $row['name'];
        
        $sendResult = sendCompleteNotification(
            $customer_id,
            $title,
            $message,
            'system'
        );
        
        if ($sendResult['database'] || $sendResult['fcm']) {
            $sent[] = [
                'customer_id' => $customer_id,
                'customer_name' => $customer_name,
                'result' => $sendResult
            ];
        } else {
            $failed[] = [
                'customer_id' => $customer_id,
                'customer_name' => $customer_name
            ];
        }
    }
    
    return [
        'total_customers' => count($sent) + count($failed),
        'sent' => $sent,
        'failed' => $failed
    ];
}

// ============================================
// API ENDPOINT
// ============================================

// Only allow POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode([
        'success' => false,
        'message' => 'Method not allowed. Only POST requests are accepted.'
    ]);
    exit();
}

// Get JSON input
$json_input = file_get_contents('php://input');
$data = json_decode($json_input, true);

// Validate action
if (!isset($data['action'])) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Action is required. Available actions: notify_by_status, notify_pending_payments, send_announcement, custom_notification'
    ]);
    exit();
}

$action = $data['action'];
$response = ['success' => false];

try {
    switch ($action) {
        
        // Notify customers by order status
        case 'notify_by_status':
            if (!isset($data['status_id'])) {
                throw new Exception('status_id is required');
            }
            
            $result = notifyOrdersByStatus(
                $data['status_id'],
                $data['title'] ?? null,
                $data['message'] ?? null
            );
            
            $response = [
                'success' => true,
                'message' => "Sent {$result['total_orders']} individual notifications for orders in status '{$result['status_name']}' to {$result['total_customers']} customers",
                'data' => $result
            ];
            break;
        
        // Notify customers with pending payments
        case 'notify_pending_payments':
            $result = notifyPendingPayments();
            
            $response = [
                'success' => true,
                'message' => "Payment reminders sent to {$result['total_customers']} customers",
                'data' => $result
            ];
            break;
        
        // Send announcement to all customers
        case 'send_announcement':
            if (!isset($data['title']) || !isset($data['message'])) {
                throw new Exception('title and message are required');
            }
            
            $result = sendAnnouncementToAll($data['title'], $data['message']);
            
            $response = [
                'success' => true,
                'message' => "Announcement sent to {$result['total_customers']} customers",
                'data' => $result
            ];
            break;
        
        // Send custom notification to specific customer
        case 'custom_notification':
            if (!isset($data['customer_id']) || !isset($data['title']) || !isset($data['message'])) {
                throw new Exception('customer_id, title, and message are required');
            }
            
            $result = sendCompleteNotification(
                intval($data['customer_id']),
                $data['title'],
                $data['message'],
                $data['type'] ?? 'general',
                $data['related_id'] ?? null,
                $data['related_type'] ?? null
            );
            
            $response = [
                'success' => true,
                'message' => 'Notification sent successfully',
                'data' => $result
            ];
            break;
        
        default:
            throw new Exception('Invalid action. Available actions: notify_by_status, notify_pending_payments, send_announcement, custom_notification');
    }
    
} catch (Exception $e) {
    http_response_code(400);
    $response = [
        'success' => false,
        'message' => $e->getMessage()
    ];
}

echo json_encode($response, JSON_PRETTY_PRINT);
mysqli_close($conn);
?>

