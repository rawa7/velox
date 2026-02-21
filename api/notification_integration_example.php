<?php
/**
 * NOTIFICATION INTEGRATION EXAMPLES
 * 
 * This file shows how to integrate notifications into your existing code
 * Copy the relevant sections into your actual files
 */

// Include the notification helper
require_once 'notification_helper.php';

// ============================================
// EXAMPLE 1: Order Status Change
// ============================================
// Add this to accept_order.php, reject_order.php, etc.

function example_orderStatusChange($order_id, $customer_id, $new_status_name) {
    // Your existing order update code...
    
    // Send notification
    $notification_id = sendOrderNotification(
        $customer_id,
        $order_id,
        $new_status_name,
        "Your order #$order_id has been updated to: $new_status_name"
    );
    
    if ($notification_id) {
        // Notification sent successfully
        error_log("Notification sent: ID $notification_id");
    }
}

// ============================================
// EXAMPLE 2: Order Accepted
// ============================================
// Add to accept_order.php after order is accepted

function example_orderAccepted($order_id, $customer_id) {
    sendNotification(
        $customer_id,
        "Order Accepted ✓",
        "Great news! Your order #$order_id has been accepted and is being processed.",
        'order',
        $order_id,
        'order'
    );
}

// ============================================
// EXAMPLE 3: Order Rejected
// ============================================
// Add to reject_order.php after order is rejected

function example_orderRejected($order_id, $customer_id, $reason = '') {
    $message = "Your order #$order_id has been rejected.";
    if (!empty($reason)) {
        $message .= " Reason: $reason";
    }
    
    sendNotification(
        $customer_id,
        "Order Rejected",
        $message,
        'order',
        $order_id,
        'order'
    );
}

// ============================================
// EXAMPLE 4: Payment Received
// ============================================
// Add this when payment is recorded

function example_paymentReceived($customer_id, $amount, $payment_id = null) {
    sendNotification(
        $customer_id,
        "Payment Received",
        "Your payment of $$amount has been successfully received and credited to your account.",
        'payment',
        $payment_id,
        'payment'
    );
}

// ============================================
// EXAMPLE 5: Low Balance Warning
// ============================================
// Send when customer balance is low

function example_lowBalanceWarning($customer_id, $current_balance, $debt_limit) {
    $available = $current_balance + $debt_limit;
    
    sendNotification(
        $customer_id,
        "Low Balance Alert",
        "Your available balance is running low. Current available: $$available. Please add funds to continue ordering.",
        'account'
    );
}

// ============================================
// EXAMPLE 6: Order Delivered
// ============================================
// When order is marked as delivered

function example_orderDelivered($order_id, $customer_id) {
    sendDeliveryNotification(
        $customer_id,
        $order_id,
        "Your order #$order_id has been delivered successfully. Thank you for your business!"
    );
}

// ============================================
// EXAMPLE 7: Order Shipped
// ============================================
// When order is shipped

function example_orderShipped($order_id, $customer_id, $tracking_number = null) {
    $message = "Your order #$order_id has been shipped and is on its way!";
    if ($tracking_number) {
        $message .= " Tracking number: $tracking_number";
    }
    
    sendDeliveryNotification($customer_id, $order_id, $message);
}

// ============================================
// EXAMPLE 8: System Announcement
// ============================================
// Send announcement to all customers

function example_sendAnnouncement() {
    $title = "System Maintenance Notice";
    $message = "Our system will be under maintenance on Sunday from 2 AM to 4 AM. We apologize for any inconvenience.";
    
    $count = sendSystemNotificationToAll($title, $message);
    echo "Sent to $count customers";
}

// ============================================
// EXAMPLE 9: Welcome Notification
// ============================================
// Send when new customer registers

function example_welcomeCustomer($customer_id, $customer_name) {
    sendNotification(
        $customer_id,
        "Welcome to Velox Shopping!",
        "Hello $customer_name! Welcome to Velox Shopping. We're excited to have you on board. Start browsing and place your first order today!",
        'system'
    );
}

// ============================================
// EXAMPLE 10: Order Awaiting Payment
// ============================================
// When order needs payment

function example_orderAwaitingPayment($order_id, $customer_id, $amount) {
    sendNotification(
        $customer_id,
        "Payment Required",
        "Your order #$order_id ($$amount) is awaiting payment. Please make payment to proceed with delivery.",
        'payment',
        $order_id,
        'order'
    );
}

// ============================================
// EXAMPLE 11: Multiple Orders Status Update
// ============================================
// Update multiple orders at once

function example_bulkOrderUpdate($order_ids, $customer_id, $status_name) {
    $order_count = count($order_ids);
    $order_list = implode(', #', $order_ids);
    
    sendNotification(
        $customer_id,
        "Multiple Orders Updated",
        "$order_count of your orders (#$order_list) have been updated to: $status_name",
        'order'
    );
}

// ============================================
// EXAMPLE 12: Price Change Notification
// ============================================
// When order price is updated

function example_priceChange($order_id, $customer_id, $old_price, $new_price) {
    $difference = abs($new_price - $old_price);
    $change_type = $new_price > $old_price ? 'increased' : 'decreased';
    
    sendNotification(
        $customer_id,
        "Order Price Updated",
        "The price for order #$order_id has been $change_type by $$difference. New total: $$new_price",
        'order',
        $order_id,
        'order'
    );
}

// ============================================
// HOW TO ADD TO EXISTING accept_order.php
// ============================================
/*

At the top of accept_order.php, add:
require_once 'notification_helper.php';

Then after the order status is updated (around line 180-200), add:

// Send notification to customer
sendOrderNotification(
    $customer_id,
    $order_id,
    "Accepted",
    "Your order #$order_id has been accepted and is being processed."
);

*/

// ============================================
// HOW TO ADD TO EXISTING reject_order.php
// ============================================
/*

At the top of reject_order.php, add:
require_once 'notification_helper.php';

Then after the order is rejected, add:

// Send notification to customer
sendOrderNotification(
    $customer_id,
    $order_id,
    "Rejected",
    "Your order #$order_id has been rejected. Please contact support for more information."
);

*/

?>

