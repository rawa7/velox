<?php
/**
 * Notification Helper
 * 
 * This file provides helper functions to send notifications to customers
 * Use this in your PHP files to automatically create notifications
 */

// Include database configuration if not already included
if (!isset($conn)) {
    include_once __DIR__ . '/../resources/config.php';
}

/**
 * Send a notification to a customer
 * 
 * @param int $customer_id Customer ID
 * @param string $title Notification title
 * @param string $message Notification message
 * @param string $type Notification type (order, payment, system, general, etc.)
 * @param int|null $related_id Related entity ID (optional)
 * @param string|null $related_type Related entity type (optional)
 * @return bool|int Returns notification ID on success, false on failure
 */
function sendNotification($customer_id, $title, $message, $type = 'general', $related_id = null, $related_type = null) {
    global $conn;
    
    // Validate required fields
    if (empty($customer_id) || empty($title) || empty($message)) {
        return false;
    }
    
    // Check if customer has bronze account (usertype = 5)
    // Bronze accounts should NOT receive any notifications
    $customer_id = intval($customer_id);
    $usertype_check = mysqli_query($conn, "SELECT usertype FROM buyer WHERE id = $customer_id");
    if ($usertype_check && $usertype_row = mysqli_fetch_assoc($usertype_check)) {
        if (intval($usertype_row['usertype']) === 5) {
            // Skip notification for bronze accounts
            return false;
        }
    }
    
    // Escape values for security
    $title = mysqli_real_escape_string($conn, $title);
    $message = mysqli_real_escape_string($conn, $message);
    $type = mysqli_real_escape_string($conn, $type);
    
    // Build query
    $query = "INSERT INTO notifications (customer_id, title, message, type, related_id, related_type) 
              VALUES ($customer_id, '$title', '$message', '$type', ";
    
    if ($related_id !== null) {
        $query .= intval($related_id);
    } else {
        $query .= "NULL";
    }
    
    $query .= ", ";
    
    if ($related_type !== null) {
        $query .= "'" . mysqli_real_escape_string($conn, $related_type) . "'";
    } else {
        $query .= "NULL";
    }
    
    $query .= ")";
    
    // Execute query
    if (mysqli_query($conn, $query)) {
        return mysqli_insert_id($conn);
    }
    
    return false;
}

/**
 * Send order notification
 * 
 * @param int $customer_id Customer ID
 * @param int $order_id Order ID
 * @param string $status_name Order status name
 * @param string $message Custom message (optional)
 * @return bool|int
 */
function sendOrderNotification($customer_id, $order_id, $status_name, $message = null) {
    if ($message === null) {
        $message = "Your order #$order_id status has been updated to: $status_name";
    }
    
    return sendNotification(
        $customer_id,
        "Order Update - #$order_id",
        $message,
        'order',
        $order_id,
        'order'
    );
}

/**
 * Send payment notification
 * 
 * @param int $customer_id Customer ID
 * @param float $amount Payment amount
 * @param string $message Custom message (optional)
 * @return bool|int
 */
function sendPaymentNotification($customer_id, $amount, $message = null) {
    if ($message === null) {
        $message = "Your payment of $$amount has been received successfully.";
    }
    
    return sendNotification(
        $customer_id,
        "Payment Received",
        $message,
        'payment'
    );
}

/**
 * Send system announcement to a customer
 * 
 * @param int $customer_id Customer ID
 * @param string $title Announcement title
 * @param string $message Announcement message
 * @return bool|int
 */
function sendSystemNotification($customer_id, $title, $message) {
    return sendNotification(
        $customer_id,
        $title,
        $message,
        'system'
    );
}

/**
 * Send system announcement to all customers
 * 
 * @param string $title Announcement title
 * @param string $message Announcement message
 * @return int Number of notifications sent
 */
function sendSystemNotificationToAll($title, $message) {
    global $conn;
    
    // Get all active customers (exclude bronze accounts - usertype = 5)
    $query = "SELECT id FROM buyer WHERE is_active = 1 AND (usertype IS NULL OR usertype != 5)";
    $result = mysqli_query($conn, $query);
    
    $count = 0;
    while ($customer = mysqli_fetch_assoc($result)) {
        if (sendSystemNotification($customer['id'], $title, $message)) {
            $count++;
        }
    }
    
    return $count;
}

/**
 * Send delivery notification
 * 
 * @param int $customer_id Customer ID
 * @param int $order_id Order ID
 * @param string $message Delivery message
 * @return bool|int
 */
function sendDeliveryNotification($customer_id, $order_id, $message) {
    return sendNotification(
        $customer_id,
        "Delivery Update - #$order_id",
        $message,
        'delivery',
        $order_id,
        'order'
    );
}

/**
 * Get unread notification count for a customer
 * 
 * @param int $customer_id Customer ID
 * @return int Unread count
 */
function getUnreadNotificationCount($customer_id) {
    global $conn;
    
    $customer_id = intval($customer_id);
    $query = "SELECT COUNT(*) as count FROM notifications WHERE customer_id = $customer_id AND is_read = 0";
    $result = mysqli_query($conn, $query);
    
    if ($result) {
        $row = mysqli_fetch_assoc($result);
        return intval($row['count']);
    }
    
    return 0;
}

/**
 * Mark notification as read
 * 
 * @param int $notification_id Notification ID
 * @param int $customer_id Customer ID (for security check)
 * @return bool
 */
function markNotificationAsRead($notification_id, $customer_id) {
    global $conn;
    
    $notification_id = intval($notification_id);
    $customer_id = intval($customer_id);
    
    $query = "UPDATE notifications SET is_read = 1 WHERE id = $notification_id AND customer_id = $customer_id";
    return mysqli_query($conn, $query);
}

/**
 * Mark all notifications as read for a customer
 * 
 * @param int $customer_id Customer ID
 * @return bool
 */
function markAllNotificationsAsRead($customer_id) {
    global $conn;
    
    $customer_id = intval($customer_id);
    $query = "UPDATE notifications SET is_read = 1 WHERE customer_id = $customer_id AND is_read = 0";
    return mysqli_query($conn, $query);
}

/**
 * Delete old read notifications (cleanup)
 * 
 * @param int $days_old Delete notifications older than this many days
 * @return int Number of deleted notifications
 */
function deleteOldNotifications($days_old = 30) {
    global $conn;
    
    $days_old = intval($days_old);
    $query = "DELETE FROM notifications WHERE is_read = 1 AND created_at < DATE_SUB(NOW(), INTERVAL $days_old DAY)";
    
    if (mysqli_query($conn, $query)) {
        return mysqli_affected_rows($conn);
    }
    
    return 0;
}

?>

